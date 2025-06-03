const express = require('express');
const multer = require('multer');
const path = require('path');
const Email = require('../models/Email');
const User = require('../models/User');
const router = express.Router();
const natural = require('natural');

const storage = multer.diskStorage({
  destination: './uploads/',
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  },
});
const upload = multer({ storage });

const authenticateJWT = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access denied, no token provided' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    res.status(403).json({ error: 'Invalid token' });
  }
};

const isValidEmail = (email) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);

const classifier = new natural.BayesClassifier();
classifier.addDocument('win money now', 'spam');
classifier.addDocument('free offer click here', 'spam');
classifier.addDocument('hello friend how are you', 'not spam');
classifier.addDocument('meeting tomorrow', 'not spam');
classifier.train();

const isSpam = (text) => classifier.classify(text) === 'spam';

router.post('/send', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { from, to, cc, bcc, subject, body, category } = req.body;
  const files = req.files;
  if (!isValidEmail(to) || (cc && !isValidEmail(cc)) || (bcc && !isValidEmail(bcc))) {
    return res.status(400).json({ error: 'Invalid email format' });
  }
  try {
    const isSpamEmail = isSpam(`${subject} ${body}`);
    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const email = new Email({
      from,
      to,
      cc,
      bcc,
      subject,
      body,
      time: new Date().toISOString(),
      category: isSpamEmail ? 'spam' : (category || 'inbox'),
      hasAttachments: files.length > 0,
      attachmentUrls,
    });
    await email.save();

    const io = req.app.get('io');
    io.to(to).emit('newEmail', { from, subject, time: email.time, isSpam: isSpamEmail });

    const user = await User.findOne({ _id: to });
    if (user && user.autoAnswerEnabled && !isSpamEmail) {
      const autoEmail = new Email({
        from: to,
        to: from,
        subject: `Re: ${subject}`,
        body: user.autoAnswerMessage,
        time: new Date().toISOString(),
        category: 'sent',
        inReplyTo: email._id,
      });
      await autoEmail.save();
      io.to(from).emit('newEmail', { from: to, subject: `Re: ${subject}`, time: autoEmail.time });
    }

    res.json({ message: 'Email sent successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/reply/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { body, to, cc, bcc } = req.body;
  if (!isValidEmail(to) || (cc && !isValidEmail(cc)) || (bcc && !isValidEmail(bcc))) {
    return res.status(400).json({ error: 'Invalid email format' });
  }
  try {
    const originalEmail = await Email.findById(emailId);
    if (!originalEmail) return res.status(404).json({ error: 'Email not found' });

    const replyEmail = new Email({
      from: req.user.userId,
      to,
      cc,
      bcc,
      subject: `Re: ${originalEmail.subject}`,
      body,
      time: new Date().toISOString(),
      category: 'sent',
      inReplyTo: emailId,
    });
    await replyEmail.save();

    const io = req.app.get('io');
    io.to(to).emit('newEmail', { from: req.user.userId, subject: replyEmail.subject, time: replyEmail.time });

    res.json({ message: 'Reply sent successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/forward/:emailId', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { emailId } = req.params;
  const { to, cc, bcc, body } = req.body;
  const files = req.files;
  if (!isValidEmail(to) || (cc && !isValidEmail(cc)) || (bcc && !isValidEmail(bcc))) {
    return res.status(400).json({ error: 'Invalid email format' });
  }
  try {
    const originalEmail = await Email.findById(emailId);
    if (!originalEmail) return res.status(404).json({ error: 'Email not found' });

    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const forwardEmail = new Email({
      from: req.user.userId,
      to,
      cc,
      bcc,
      subject: `Fwd: ${originalEmail.subject}`,
      body: `${body}\n\n----- Forwarded Message -----\nFrom: ${originalEmail.from}\nSubject: ${originalEmail.subject}\n\n${originalEmail.body}`,
      time: new Date().toISOString(),
      category: 'sent',
      hasAttachments: files.length > 0 || originalEmail.hasAttachments,
      attachmentUrls: [...attachmentUrls, ...originalEmail.attachmentUrls],
      forwardedFrom: emailId,
    });
    await forwardEmail.save();

    const io = req.app.get('io');
    io.to(to).emit('newEmail', { from: req.user.userId, subject: forwardEmail.subject, time: forwardEmail.time });

    res.json({ message: 'Email forwarded successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/draft', authenticateJWT, upload.array('attachments'), async (req, res) => {
  const { from, to, cc, bcc, subject, body } = req.body;
  const files = req.files;
  if (to && !isValidEmail(to) || (cc && !isValidEmail(cc)) || (bcc && !isValidEmail(bcc))) {
    return res.status(400).json({ error: 'Invalid email format' });
  }
  try {
    const attachmentUrls = files.map(file => `/uploads/${file.filename}`);
    const draftEmail = new Email({
      from,
      to,
      cc,
      bcc,
      subject,
      body,
      time: new Date().toISOString(),
      category: 'draft',
      hasAttachments: files.length > 0,
      attachmentUrls,
    });
    await draftEmail.save();

    res.json({ message: 'Draft saved successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/action/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { isRead, isStarred, category, labels } = req.body;
  try {
    const email = await Email.findById(emailId);
    if (!email || (email.to !== req.user.userId && email.from !== req.user.userId)) {
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

    res.json({ message: 'Email updated successfully' });
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
  try {
    const emails = await Email.find({ $or: [{ to: userId }, { from: userId }], category })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .sort({ time: -1 });
    const total = await Email.countDocuments({ $or: [{ to: userId }, { from: userId }], category });
    res.json({ emails, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/search/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  const { keyword, from, to, hasAttachments, startDate, endDate, label } = req.query;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    let query = { $or: [{ to: userId }, { from: userId }] };
    if (keyword) {
      query = {
        ...query,
        $or: [
          { subject: { $regex: keyword, $options: 'i' } },
          { body: { $regex: keyword, $options: 'i' } },
        ],
      };
    }
    if (from && isValidEmail(from)) query.from = from;
    else if (from) return res.status(400).json({ error: 'Invalid from email' });
    if (to && isValidEmail(to)) query.to = to;
    else if (to) return res.status(400).json({ error: 'Invalid to email' });
    if (hasAttachments !== undefined) query.hasAttachments = hasAttachments === 'true';
    if (startDate || endDate) {
      query.time = {};
      if (startDate) query.time.$gte = startDate;
      if (endDate) query.time.$lte = endDate;
    }
    if (label) query.labels = label;

    const emails = await Email.find(query)
      .skip((parseInt(req.query.page || 1) - 1) * parseInt(req.query.limit || 10))
      .limit(parseInt(req.query.limit || 10))
      .sort({ time: -1 });
    const total = await Email.countDocuments(query);
    res.json({ emails, total, page: parseInt(req.query.page || 1), limit: parseInt(req.query.limit || 10) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;