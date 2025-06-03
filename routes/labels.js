const express = require('express');
const Label = require('../models/Label');
const Email = require('../models/Email');
const router = express.Router();

// Import shared middleware
const authenticateJWT = require('../utils/authMiddleware');

router.post('/', authenticateJWT, async (req, res) => {
  // userId should be taken from authenticated user, not request body for security
  const { name } = req.body;
  const userId = req.user.userId;

  try {
    // Check if label with the same name already exists for this user
    const existingLabel = await Label.findOne({ userId, name });
    if (existingLabel) {
      return res.status(400).json({ error: 'Label with this name already exists' });
    }
    const label = new Label({ userId, name });
    await label.save();
    res.status(201).json(label);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/:labelId', authenticateJWT, async (req, res) => {
  const { labelId } = req.params;
  const { name } = req.body;
  const userId = req.user.userId;

  try {
    const label = await Label.findById(labelId);
    if (!label) {
        return res.status(404).json({ error: 'Label not found' });
    }
    if (label.userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized to update this label' });
    }

    // Check if the new name conflicts with an existing label for the same user
    if (name !== label.name) {
        const existingLabel = await Label.findOne({ userId, name, _id: { $ne: labelId } });
        if (existingLabel) {
          return res.status(400).json({ error: 'Another label with this name already exists' });
        }
    }

    const oldName = label.name;
    label.name = name;
    await label.save();

    // Update emails that have the old label name for this user
    if (oldName !== name) {
      await Email.updateMany(
        { $or: [{ to: userId }, { from: userId }], labels: oldName },
        { $set: { 'labels.$[elem]': name } },
        { arrayFilters: [{ elem: oldName }] }
      );
    }
    res.json({ message: 'Label updated successfully', label });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.delete('/:labelId', authenticateJWT, async (req, res) => {
  const { labelId } = req.params;
  const userId = req.user.userId;
  try {
    const label = await Label.findById(labelId);
    if (!label) {
        return res.status(404).json({ error: 'Label not found' });
    }
    if (label.userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized to delete this label' });
    }

    const labelName = label.name;
    await Label.deleteOne({ _id: labelId }); // Use deleteOne

    // Remove the label from all emails of this user
    await Email.updateMany(
      { $or: [{ to: userId }, { from: userId }], labels: labelName },
      { $pull: { labels: labelName } }
    );
    res.json({ message: 'Label deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/assign/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { label: labelName } = req.body; // Expecting label name
  const userId = req.user.userId;

  try {
    const email = await Email.findById(emailId);
    if (!email) return res.status(404).json({ error: 'Email not found' });
    if (email.to !== userId && email.from !== userId && (!email.cc || !email.cc.includes(userId)) && (!email.bcc || !email.bcc.includes(userId))) {
      return res.status(403).json({ error: 'Unauthorized to modify this email' });
    }

    // Ensure the label exists for the user
    const labelExists = await Label.findOne({ userId, name: labelName });
    if (!labelExists) {
        return res.status(400).json({ error: `Label '${labelName}' does not exist.` });
    }

    if (!email.labels.includes(labelName)) {
      email.labels.push(labelName);
      await email.save();
    }
    res.json({ message: `Label '${labelName}' assigned successfully`, email });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/remove-label/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { label: labelName } = req.body; // Expecting label name
  const userId = req.user.userId;

  try {
    const email = await Email.findById(emailId);
    if (!email) return res.status(404).json({ error: 'Email not found' });
     if (email.to !== userId && email.from !== userId && (!email.cc || !email.cc.includes(userId)) && (!email.bcc || !email.bcc.includes(userId))) {
      return res.status(403).json({ error: 'Unauthorized to modify this email' });
    }

    email.labels = email.labels.filter(l => l !== labelName);
    await email.save();
    res.json({ message: `Label '${labelName}' removed successfully`, email });
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

router.get('/emails/:userId/:labelName', authenticateJWT, async (req, res) => {
  const { userId, labelName } = req.params;
  const { page = 1, limit = 10 } = req.query;

  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const query = {
      $or: [{ to: userId }, { from: userId }],
      labels: labelName
    };
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