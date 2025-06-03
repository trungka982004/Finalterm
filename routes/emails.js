const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs'); // For classifier loading/saving
const Email = require('../models/Email');
const User = require('../models/User');
const router = express.Router();
const natural = require('natural');

// Import shared middleware (no longer need local authenticateJWT or isValidEmail definitions)
const authenticateJWT = require('../utils/authMiddleware');
// isValidEmail is not used in this file anymore if to/cc/bcc are User IDs for internal comms

const storage = multer.diskStorage({
  destination: './uploads/',
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});
const upload = multer({ storage }); // Add file size/type limits here if needed

// Spam Classifier Setup
let classifier = new natural.BayesClassifier();
const classifierPath = './spam_classifier.json'; // Path to save/load classifier

try {
  const classifierData = fs.readFileSync(classifierPath, 'utf8');
  classifier = natural.BayesClassifier.restore(JSON.parse(classifierData));
  console.log('Spam classifier loaded from file.');
} catch (error) {
  console.log('No pre-trained classifier found or error loading, training new one...');
  // Minimal training data - EXPAND THIS SIGNIFICANTLY FOR EFFECTIVENESS
  classifier.addDocument('win money now instant prize', 'spam');
  classifier.addDocument('free exclusive offer click here limited time', 'spam');
  classifier.addDocument('nigerian prince needs your help with funds', 'spam');
  classifier.addDocument('enlarge your xxx product now', 'spam');
  classifier.addDocument('urgent account verification needed immediately', 'spam');

  classifier.addDocument('hello friend how are you doing today', 'not spam');
  classifier.addDocument('meeting scheduled for tomorrow at 10am', 'not spam');
  classifier.addDocument('project update and next steps discussion', 'not spam');
  classifier.addDocument('invoice for recent purchase order #12345', 'not spam');
  classifier.addDocument('family gathering next weekend, hope you can make it', 'not spam');
  classifier.train();
  try {
    fs.writeFileSync(classifierPath, JSON.stringify(classifier));
    console.log('New spam classifier trained and saved.');
  } catch (saveError) {
    console.error('Could not save new classifier:', saveError);
  }
}

const isSpam = (text) => classifier.classify(text) === 'spam';

router.post('/send', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { to, cc, bcc, subject, body, category } = req.body; // 'from' is now taken from req.user.userId
  const files = req.files;

  // Assuming to, cc, bcc are User._id strings for internal communication.
  // No longer using isValidEmail for these fields here. Validation might involve checking if User._id exists.

  try {
    const isSpamEmail = isSpam(`${subject} ${body}`);
    const attachmentUrls = files.map(file => `/uploads/${file.filename}`); // Store relative paths

    const email = new Email({
      from: req.user.userId, // Set 'from' from authenticated user
      to, // Assumed to be a User._id
      cc, // Assumed to be User._id(s)
      bcc, // Assumed to be User._id(s)
      subject,
      body,
      time: new Date().toISOString(),
      category: isSpamEmail ? 'spam' : (category || 'inbox'),
      hasAttachments: files.length > 0,
      attachmentUrls,
    });
    await email.save();

    const io = req.app.get('io');
    // Notify recipient(s) - 'to' should be a User._id or an array of User._id for cc/bcc handling
    // For simplicity, emitting to the primary 'to' user.
    // If 'to' is an array or cc/bcc are also User IDs, you'd loop or use multiple io.to()
    if (email.to) {
        io.to(email.to).emit('newEmail', {
            _id: email._id, // Send email ID
            from: req.user.userId, // Or fetch sender's display name/email
            subject: email.subject,
            time: email.time,
            isSpam: isSpamEmail
        });
    }
    // Handle cc/bcc notifications similarly if they are User IDs
    // Example for cc (assuming cc is a single User ID for simplicity here, adapt if it's a list):
    // if (email.cc) {
    //     io.to(email.cc).emit('newEmail', { /* ... */ });
    // }


    // Auto-reply logic
    const recipientUser = await User.findById(to); // 'to' is the recipient's User._id
    if (recipientUser && recipientUser.autoAnswerEnabled && !isSpamEmail) {
      const autoReplyEmail = new Email({
        from: to, // Auto-reply comes from the original recipient (now sender of auto-reply)
        to: req.user.userId, // Auto-reply goes to the original sender
        subject: `Re: ${subject}`,
        body: recipientUser.autoAnswerMessage,
        time: new Date().toISOString(),
        category: 'sent', // Auto-replies are 'sent' from the perspective of the auto-answering user
        inReplyTo: email._id.toString(),
      });
      await autoReplyEmail.save();
      // Notify the original sender about the auto-reply
      io.to(req.user.userId).emit('newEmail', {
          _id: autoReplyEmail._id,
          from: to, // Sender of auto-reply (original recipient)
          subject: autoReplyEmail.subject,
          time: autoReplyEmail.time
      });
    }

    res.json({ message: 'Email sent successfully', emailId: email._id });
  } catch (error) {
    console.error("Error sending email:", error);
    res.status(500).json({ error: error.message });
  }
});

router.post('/reply/:emailId', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { emailId } = req.params;
  const { to, cc, bcc, body } = req.body; // 'from' is from req.user.userId
  const files = req.files;

  // Assuming to, cc, bcc are User._id strings
  try {
    const originalEmail = await Email.findById(emailId);
    if (!originalEmail) return res.status(404).json({ error: 'Original email not found' });

    // Ensure user is authorized to reply (e.g., was a recipient or sender of original)
    // This check might need refinement based on exact authorization rules
    if (originalEmail.to !== req.user.userId && originalEmail.from !== req.user.userId && (!originalEmail.cc || !originalEmail.cc.includes(req.user.userId)) && (!originalEmail.bcc || !originalEmail.bcc.includes(req.user.userId))) {
        // A more complex check if cc/bcc are arrays of UserIDs
        // return res.status(403).json({ error: 'Unauthorized to reply to this email' });
    }


    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const replyEmail = new Email({
      from: req.user.userId,
      to, // recipient of the reply (could be originalEmail.from)
      cc,
      bcc,
      subject: `Re: ${originalEmail.subject}`,
      body,
      time: new Date().toISOString(),
      category: 'sent',
      hasAttachments: files.length > 0,
      attachmentUrls,
      inReplyTo: emailId,
    });
    await replyEmail.save();

    const io = req.app.get('io');
    if (replyEmail.to) {
        io.to(replyEmail.to).emit('newEmail', {
            _id: replyEmail._id,
            from: req.user.userId,
            subject: replyEmail.subject,
            time: replyEmail.time
        });
    }
    // Handle cc/bcc notifications

    res.json({ message: 'Reply sent successfully', emailId: replyEmail._id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/forward/:emailId', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { emailId } = req.params;
  const { to, cc, bcc, body: forwardMessageBody } = req.body; // 'from' is from req.user.userId
  const files = req.files; // New attachments for the forward email

  // Assuming to, cc, bcc are User._id strings
  try {
    const originalEmail = await Email.findById(emailId);
    if (!originalEmail) return res.status(404).json({ error: 'Original email not found' });

    // Fetch details of original sender for the forwarded message body
    let originalSenderDisplay = originalEmail.from; // This is a User ID
    try {
        const originalSenderUser = await User.findById(originalEmail.from).select('name email phone');
        if (originalSenderUser) {
            originalSenderDisplay = originalSenderUser.name || originalSenderUser.email || originalSenderUser.phone;
        }
    } catch (e) { console.error("Could not fetch original sender details for forward", e); }


    const newAttachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const combinedAttachmentUrls = [...newAttachmentUrls, ...originalEmail.attachmentUrls];

    const forwardEmail = new Email({
      from: req.user.userId,
      to,
      cc,
      bcc,
      subject: `Fwd: ${originalEmail.subject}`,
      body: `${forwardMessageBody}\n\n----- Forwarded Message -----\nFrom: ${originalSenderDisplay}\nTo: ${originalEmail.to} \nSubject: ${originalEmail.subject}\n\n${originalEmail.body}`,
      time: new Date().toISOString(),
      category: 'sent',
      hasAttachments: combinedAttachmentUrls.length > 0,
      attachmentUrls: combinedAttachmentUrls,
      forwardedFrom: emailId,
    });
    await forwardEmail.save();

    const io = req.app.get('io');
    if (forwardEmail.to) {
        io.to(forwardEmail.to).emit('newEmail', {
            _id: forwardEmail._id,
            from: req.user.userId,
            subject: forwardEmail.subject,
            time: forwardEmail.time
        });
    }
    // Handle cc/bcc notifications

    res.json({ message: 'Email forwarded successfully', emailId: forwardEmail._id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/draft', authenticateJWT, upload.array('attachments'), async (req, res) => {
  // 'from' is from req.user.userId. 'to', 'cc', 'bcc' can be empty for drafts or User._ids
  const { to, cc, bcc, subject, body } = req.body;
  const files = req.files;

  try {
    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const draftEmail = new Email({
      from: req.user.userId,
      to: to || '', // Can be empty
      cc: cc || '',
      bcc: bcc || '',
      subject: subject || '', // Can be empty
      body: body || '',
      time: new Date().toISOString(),
      category: 'draft',
      hasAttachments: files.length > 0,
      attachmentUrls,
    });
    await draftEmail.save();

    res.json({ message: 'Draft saved successfully', emailId: draftEmail._id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/action/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { isRead, isStarred, category, labels } = req.body;
  try {
    const email = await Email.findById(emailId);
    // Ensure the user is involved in the email (sender or recipient)
    if (!email || (email.to !== req.user.userId && email.from !== req.user.userId && (!email.cc || !email.cc.includes(req.user.userId)) && (!email.bcc || !email.bcc.includes(req.user.userId)))) {
      return res.status(403).json({ error: 'Unauthorized or email not found' });
    }

    if (isRead !== undefined) email.isRead = isRead;
    if (isStarred !== undefined) email.isStarred = isStarred;
    if (category && ['inbox', 'sent', 'draft', 'trash', 'archive', 'spam'].includes(category)) {
      email.category = category;
    }
    if (labels) email.labels = labels; // Expects an array of label strings or label IDs
    await email.save();

    const io = req.app.get('io');
    io.to(req.user.userId).emit('emailUpdated', email); // Notify user about the update

    res.json({ message: 'Email updated successfully', email });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:userId/:category', authenticateJWT, async (req, res) => {
  const { userId, category } = req.params;
  const { page = 1, limit = 10 } = req.query;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  // Validate category
  if (!['inbox', 'sent', 'draft', 'trash', 'archive', 'spam', 'starred'].includes(category.toLowerCase())) {
    return res.status(400).json({ error: 'Invalid category' });
  }
  
  try {
    let query = { $or: [{ to: userId }, { from: userId }] };
    if (category.toLowerCase() === 'inbox') {
        query.to = userId;
        query.category = { $in: ['inbox', 'spam'] }; // Inbox typically shows incoming mail
    } else if (category.toLowerCase() === 'sent') {
        query.from = userId;
        query.category = 'sent';
    } else if (category.toLowerCase() === 'starred') {
        query.isStarred = true;
        // query.category = {$ne: 'trash'}; // Optionally exclude trash
    } else {
        query.category = category.toLowerCase();
    }


    const emails = await Email.find(query)
      .sort({ time: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));
      
    const total = await Email.countDocuments(query);
    res.json({ emails, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/search/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  const { keyword, from, to, hasAttachments, startDate, endDate, label, page = 1, limit = 10 } = req.query;

  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    let query = { $or: [{ to: userId }, { from: userId }] }; // Base query: user is involved

    if (keyword) {
      query.$and = query.$and || []; // Initialize $and if it doesn't exist
      query.$and.push({
        $or: [
          { subject: { $regex: keyword, $options: 'i' } },
          { body: { $regex: keyword, $options: 'i' } },
          // Consider searching from/to display names if you store/resolve them
        ],
      });
    }

    // Assuming 'from' and 'to' query params are User._ids or emails to be resolved to User._ids
    if (from) { // 'from' is a search filter for emails *received from* this user ID
      query.from = from; // This 'from' refers to the 'from' field in Email schema
    }
    if (to) { // 'to' is a search filter for emails *sent to* this user ID
       query.to = to; // This 'to' refers to the 'to' field in Email schema
    }

    if (hasAttachments !== undefined) {
      query.hasAttachments = hasAttachments === 'true';
    }
    if (startDate || endDate) {
      query.time = {};
      if (startDate) query.time.$gte = new Date(startDate).toISOString();
      if (endDate) query.time.$lte = new Date(endDate).toISOString();
    }
    if (label) {
      query.labels = label; // Assumes label is a string matching one in the labels array
    }

    const emails = await Email.find(query)
      .sort({ time: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));
    const total = await Email.countDocuments(query);
    res.json({ emails, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;