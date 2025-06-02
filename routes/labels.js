const express = require('express');
const Label = require('../models/Label');
const Email = require('../models/Email');
const router = express.Router();

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

router.post('/', authenticateJWT, async (req, res) => {
  const { userId, name } = req.body;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const label = new Label({ userId, name });
    await label.save();
    res.json(label);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/:labelId', authenticateJWT, async (req, res) => {
  const { labelId } = req.params;
  const { name } = req.body;
  try {
    const label = await Label.findById(labelId);
    if (!label || label.userId !== req.user.userId) {
      return res.status(403).json({ error: 'Unauthorized or label not found' });
    }
    const oldName = label.name;
    label.name = name;
    await label.save();
    await Email.updateMany(
      { labels: oldName, $or: [{ to: req.user.userId }, { from: req.user.userId }] },
      { $set: { 'labels.$[elem]': name } },
      { arrayFilters: [{ elem: oldName }] }
    );
    res.json({ message: 'Label updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.delete('/:labelId', authenticateJWT, async (req, res) => {
  const { labelId } = req.params;
  try {
    const label = await Label.findById(labelId);
    if (!label || label.userId !== req.user.userId) {
      return res.status(403).json({ error: 'Unauthorized or label not found' });
    }
    await Label.deleteOne({ _id: labelId });
    await Email.updateMany(
      { labels: label.name, $or: [{ to: req.user.userId }, { from: req.user.userId }] },
      { $pull: { labels: label.name } }
    );
    res.json({ message: 'Label deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/assign/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { label } = req.body;
  try {
    const email = await Email.findById(emailId);
    if (!email || (email.to !== req.user.userId && email.from !== req.user.userId)) {
      return res.status(403).json({ error: 'Unauthorized or email not found' });
    }
    if (!email.labels.includes(label)) {
      email.labels.push(label);
      await email.save();
    }
    res.json({ message: 'Label assigned successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/remove-label/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { label } = req.body;
  try {
    const email = await Email.findById(emailId);
    if (!email || (email.to !== req.user.userId && email.from !== req.user.userId)) {
      return res.status(403).json({ error: 'Unauthorized or email not found' });
    }
    email.labels = email.labels.filter(l => l !== label);
    await email.save();
    res.json({ message: 'Label removed successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const labels = await Label.find({ userId });
    res.json(labels);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/emails/:userId/:label', authenticateJWT, async (req, res) => {
  const { userId, label } = req.params;
  const { page = 1, limit = 10 } = req.query;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const emails = await Email.find({ $or: [{ to: userId }, { from: userId }], labels: label })
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .sort({ time: -1 });
    const total = await Email.countDocuments({ $or: [{ to: userId }, { from: userId }], labels: label });
    res.json({ emails, total, page: parseInt(page), limit: parseInt(limit) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;