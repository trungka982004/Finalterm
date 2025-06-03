const express = require('express');
const User = require('../models/User');
const router = express.Router();

// Import shared middleware
const authenticateJWT = require('../utils/authMiddleware');

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

    if (notificationSettings) {
        // Add more specific validation for notificationSettings structure if needed
        user.notificationSettings = { ...user.notificationSettings, ...notificationSettings };
    }
    if (autoAnswerEnabled !== undefined) user.autoAnswerEnabled = autoAnswerEnabled;
    if (autoAnswerMessage !== undefined) user.autoAnswerMessage = autoAnswerMessage; // Allow empty string
    await user.save();

    // Return the updated user settings
    const updatedUserSettings = {
        notificationSettings: user.notificationSettings,
        autoAnswerEnabled: user.autoAnswerEnabled,
        autoAnswerMessage: user.autoAnswerMessage,
    };
    res.json({ message: 'Settings updated successfully', settings: updatedUserSettings });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;