const express = require('express');
const User = require('../models/User');
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

router.get('/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const user = await User.findById(userId).select('notificationSettings autoAnswerEnabled autoAnswerMessage');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  const { notificationSettings, autoAnswerEnabled, autoAnswerMessage } = req.body;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (notificationSettings) user.notificationSettings = notificationSettings;
    if (autoAnswerEnabled !== undefined) user.autoAnswerEnabled = autoAnswerEnabled;
    if (autoAnswerMessage) user.autoAnswerMessage = autoAnswerMessage;
    await user.save();

    res.json({ message: 'Settings updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;