const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Email = require('../models/Email');
const User = require('../models/User');
const router = express.Router();
const natural = require('natural');

// Import shared middleware
const authenticateJWT = require('../utils/authMiddleware');

const storage = multer.diskStorage({
  destination: './uploads/',
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});

// File validation for attachments
const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'application/pdf', 'text/plain'];
    if (!allowedTypes.includes(file.mimetype)) {
      return cb(new Error('Invalid file type. Allowed: JPEG, PNG, PDF, TXT'));
    }
    cb(null, true);
  },
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
});

// Spam Classifier Setup
let classifier = new natural.BayesClassifier();
const classifierPath = './spam_classifier.json';

// Expanded training data
const trainingData = [
  // Spam examples
  { text: 'win million dollars now instant cash prize', label: 'spam' },
  { text: 'free viagra exclusive offer click here', label: 'spam' },
  { text: 'nigerian prince urgent funds transfer', label: 'spam' },
  { text: 'enlarge your product cheap pills', label: 'spam' },
  { text: 'account suspended verify now', label: 'spam' },
  { text: 'lottery winner claim your prize', label: 'spam' },
  { text: 'cheap rolex watches limited offer', label: 'spam' },
  { text: 'urgent action needed bank account', label: 'spam' },
  { text: 'get rich quick scheme join now', label: 'spam' },
  { text: 'free gift card click to claim', label: 'spam' },
  // Non-spam examples
  { text: 'hello friend how are you today', label: 'not spam' },
  { text: 'meeting tomorrow at 10am conference room', label: 'not spam' },
  { text: 'project update please review', label: 'not spam' },
  { text: 'invoice for order #12345 due next week', label: 'not spam' },
  { text: 'family dinner this weekend RSVP', label: 'not spam' },
  { text: 'team meeting agenda for Monday', label: 'not spam' },
  { text: 'thank you for your feedback', label: 'not spam' },
  { text: 'weekly report submission reminder', label: 'not spam' },
  { text: 'happy birthday celebration invite', label: 'not spam' },
  { text: 'contract review meeting next Friday', label: 'not spam' },
];

try {
  const classifierData = fs.readFileSync(classifierPath, 'utf8');
  classifier = natural.BayesClassifier.restore(JSON.parse(classifierData));
  console.log('Spam classifier loaded from file.');
} catch (error) {
  console.log('Training new spam classifier...');
  trainingData.forEach(({ text, label }) => classifier.addDocument(text, label));
  classifier.train();
  try {
    fs.writeFileSync(classifierPath, JSON.stringify(classifier));
    console.log('New spam classifier trained and saved.');
  } catch (saveError) {
    console.error('Could not save classifier:', saveError);
  }
}

const isSpam = (text) => classifier.classify(text) === 'spam';

// Validate User IDs
const validateUserIds = async (ids) => {
  if (!Array.isArray(ids)) ids = [ids]; // Handle single ID or array
  for (const id of ids.filter(id => id)) { // Skip empty IDs
    if (!mongoose.isValidObjectId(id) || !(await User.exists({ _id: id }))) {
      throw new Error(`Invalid or non-existent User ID: ${id}`);
    }
  }
};

router.post('/send', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { to, cc, bcc, subject, body, category } = req.body;
  const files = req.files;

  try {
    // Validate User IDs
    await validateUserIds([to, ...(cc || []), ...(bcc || [])]);

    const isSpamEmail = isSpam(`${subject} ${body}`);
    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);

    const email = new Email({
      from: req.user.userId,
      to,
      cc: cc || [],
      bcc: bcc || [],
      subject,
      body,
      time: new Date().toISOString(),
      category: isSpamEmail ? 'spam' : (category || 'inbox'),
      hasAttachments: files.length > 0,
      attachmentUrls,
    });
    await email.save();

    const io = req.app.get('io');
    // Notify all recipients (to, cc, bcc)
    const notifyUsers = [email.to, ...(email.cc || []), ...(email.bcc || [])].filter(id => id);
    for (const userId of notifyUsers) {
      io.to(userId).emit('newEmail', {
        _id: email._id,
        from: req.user.userId,
        subject: email.subject,
        time: email.time,
        isSpam: isSpamEmail,
      });
    }

    // Auto-reply logic
    const recipientUser = await User.findById(to);
    if (recipientUser && recipientUser.autoAnswerEnabled && !isSpamEmail) {
      const autoReplyEmail = new Email({
        from: to,
        to: req.user.userId,
        subject: `Re: ${subject}`,
        body: recipientUser.autoAnswerMessage,
        time: new Date().toISOString(),
        category: 'sent',
        inReplyTo: email._id,
      });
      await autoReplyEmail.save();
      io.to(req.user.userId).emit('newEmail', {
        _id: autoReplyEmail._id,
        from: to,
        subject: autoReplyEmail.subject,
        time: autoReplyEmail.time,
      });
    }

    res.json({ message: 'Email sent successfully', emailId: email._id });
  } catch (error) {
    console.error('Error sending email:', error);
    res.status(500).json({ error: error.message });
  }
});

router.post('/reply/:emailId', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { emailId } = req.params;
  const { to, cc, bcc, body } = req.body;
  const files = req.files;

  try {
    // Validate User IDs
    await validateUserIds([to, ...(cc || []), ...(bcc || [])]);

    const originalEmail = await Email.findById(emailId);
    if (!originalEmail) return res.status(404).json({ error: 'Original email not found' });

    // Authorization: User must be sender, recipient, or in cc/bcc
    const authorizedUsers = [
      originalEmail.from.toString(),
      originalEmail.to.toString(),
      ...(originalEmail.cc || []).map(id => id.toString()),
      ...(originalEmail.bcc || []).map(id => id.toString()),
    ];
    if (!authorizedUsers.includes(req.user.userId)) {
      return res.status(403).json({ error: 'Unauthorized to reply to this email' });
    }

    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const replyEmail = new Email({
      from: req.user.userId,
      to,
      cc: cc || [],
      bcc: bcc || [],
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
    const notifyUsers = [replyEmail.to, ...(replyEmail.cc || []), ...(replyEmail.bcc || [])].filter(id => id);
    for (const userId of notifyUsers) {
      io.to(userId).emit('newEmail', {
        _id: replyEmail._id,
        from: req.user.userId,
        subject: replyEmail.subject,
        time: replyEmail.time,
      });
    }

    res.json({ message: 'Reply sent successfully', emailId: replyEmail._id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/forward/:emailId', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { emailId } = req.params;
  const { to, cc, bcc, body: forwardMessageBody } = req.body;
  const files = req.files;

  try {
    // Validate User IDs
    await validateUserIds([to, ...(cc || []), ...(bcc || [])]);

    const originalEmail = await Email.findById(emailId);
    if (!originalEmail) return res.status(404).json({ error: 'Original email not found' });

    let originalSenderDisplay = originalEmail.from;
    try {
      const originalSenderUser = await User.findById(originalEmail.from).select('name email phone');
      if (originalSenderUser) {
        originalSenderDisplay = originalSenderUser.name || originalSenderUser.email || originalSenderUser.phone;
      }
    } catch (e) {
      console.error('Could not fetch original sender details:', e);
    }

    const newAttachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const combinedAttachmentUrls = [...newAttachmentUrls, ...originalEmail.attachmentUrls];

    const forwardEmail = new Email({
      from: req.user.userId,
      to,
      cc: cc || [],
      bcc: bcc || [],
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
    const notifyUsers = [forwardEmail.to, ...(forwardEmail.cc || []), ...(forwardEmail.bcc || [])].filter(id => id);
    for (const userId of notifyUsers) {
      io.to(userId).emit('newEmail', {
        _id: forwardEmail._id,
        from: req.user.userId,
        subject: forwardEmail.subject,
        time: forwardEmail.time,
      });
    }

    res.json({ message: 'Email forwarded successfully', emailId: forwardEmail._id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/draft', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { to, cc, bcc, subject, body } = req.body;
  const files = req.files;

  try {
    // Validate User IDs (optional for drafts)
    if (to || cc || bcc) {
      await validateUserIds([to, ...(cc || []), ...(bcc || [])]);
    }

    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const draftEmail = new Email({
      from: req.user.userId,
      to: to || null,
      cc: cc || [],
      bcc: bcc || [],
      subject: subject || '',
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
    if (!email) return res.status(404).json({ error: 'Email not found' });

    // Authorization: User must be sender, recipient, or in cc/bcc
    const authorizedUsers = [
      email.from.toString(),
      email.to.toString(),
      ...(email.cc || []).map(id => id.toString()),
      ...(email.bcc || []).map(id => id.toString()),
    ];
    if (!authorizedUsers.includes(req.user.userId)) {
      return res.status(403).json({ error: 'Unauthorized or email not found' });
    }

    if (isRead !== undefined) email.isRead = isRead;
    if (isStarred !== undefined) email.isStarred = isStarred;
    if (category && ['inbox', 'sent', 'draft', 'trash', 'archive', 'spam'].includes(category)) {
      email.category = category;
    }
    if (labels) email.labels = labels;
    await email.save();

    const io = req.app.get('io');
    io.to(req.user.userId).emit('emailUpdated', email);

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
  if (!['inbox', 'sent', 'draft', 'trash', 'archive', 'spam', 'starred'].includes(category.toLowerCase())) {
    return res.status(400).json({ error: 'Invalid category' });
  }

  try {
    let query = { $or: [{ to: userId }, { from: userId }, { cc: userId }, { bcc: userId }] };
    if (category.toLowerCase() === 'inbox') {
      query.to = userId;
      query.category = { $in: ['inbox', 'spam'] };
    } else if (category.toLowerCase() === 'sent') {
      query.from = userId;
      query.category = 'sent';
    } else if (category.toLowerCase() === 'starred') {
      query.isStarred = true;
    } else {
      query.category = category.toLowerCase();
    }

    const emails = await Email.find(query)
      .sort({ time: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(Math.min(parseInt(limit), 100)); // Cap limit at 100
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
    let query = { $or: [{ to: userId }, { from: userId }, { cc: userId }, { bcc: userId }] };

    if (keyword) {
      query.$and = query.$and || [];
      query.$and.push({
        $or: [
          { subject: { $regex: keyword, $options: 'i' } },
          { body: { $regex: keyword, $options: 'i' } },
        ],
      });
    }

    if (from) {
      if (!mongoose.isValidObjectId(from) || !(await User.exists({ _id: from }))) {
        return res.status(400).json({ error: 'Invalid from User ID' });
      }
      query.from = from;
    }
    if (to) {
      if (!mongoose.isValidObjectId(to) || !(await User.exists({ _id: to }))) {
        return res.status(400).json({ error: 'Invalid to User ID' });
      }
      query.to = to;
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
      query.labels = label;
    }

    const emails = await Email.find(query)
      .sort({ time: -1 })
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(Math.min(parseInt(limit), 100));
    const total = await Email.countDocuments(query);
    res.json({ emails, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;