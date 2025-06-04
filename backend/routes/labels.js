const express = require('express');
const Label = require('../models/Label');
const Email = require('../models/Email');
const router = express.Router();

// Import shared middleware
const authenticateJWT = require('../utils/authMiddleware');

router.post('/', authenticateJWT, async (req, res) => {
  const { name } = req.body;
  const userId = req.user.userId;

  try {
    if (!name || typeof name !== 'string' || name.trim() === '' || name.length > 50) {
      return res.status(400).json({ error: 'Label name must be a non-empty string (max 50 characters)' });
    }
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
    if (!name || typeof name !== 'string' || name.trim() === '' || name.length > 50) {
      return res.status(400).json({ error: 'Label name must be a non-empty string (max 50 characters)' });
    }
    const label = await Label.findById(labelId);
    if (!label) {
      return res.status(404).json({ error: 'Label not found' });
    }
    if (label.userId !== userId) {
      return res.status(403).json({ error: 'Unauthorized to update this label' });
    }

    if (name !== label.name) {
      const existingLabel = await Label.findOne({ userId, name, _id: { $ne: labelId } });
      if (existingLabel) {
        return res.status(400).json({ error: 'Another label with this name already exists' });
      }
    }

    const oldName = label.name;
    label.name = name;
    await label.save();

    if (oldName !== name) {
      await Email.updateMany(
        { $or: [{ to: userId }, { from: userId }, { cc: userId }, { bcc: userId }], labels: oldName },
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
    await Label.deleteOne({ _id: labelId });

    await Email.updateMany(
      { $or: [{ to: userId }, { from: userId }, { cc: userId }, { bcc: userId }], labels: labelName },
      { $pull: { labels: labelName } }
    );
    res.json({ message: 'Label deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/assign/:emailId', authenticateJWT, async (req, res) => {
  const { emailId } = req.params;
  const { label: labelName } = req.body;
  const userId = req.user.userId;

  try {
    const email = await Email.findById(emailId);
    if (!email) return res.status(404).json({ error: 'Email not found' });

    const authorizedUsers = [
      email.from.toString(),
      email.to.toString(),
      ...(email.cc || []).map(id => id.toString()),
      ...(email.bcc || []).map(id => id.toString()),
    ];
    if (!authorizedUsers.includes(userId)) {
      return res.status(403).json({ error: 'Unauthorized to modify this email' });
    }

    const labelExists = await Label.findOne({ userId, name: labelName });
    if (!labelExists) {
      return res.status(400).json({ error: `Label '${labelName}' does not exist` });
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
  const { label: labelName } = req.body;
  const userId = req.user.userId;

  try {
    const email = await Email.findById(emailId);
    if (!email) return res.status(404).json({ error: 'Email not found' });

    const authorizedUsers = [
      email.from.toString(),
      email.to.toString(),
      ...(email.cc || []).map(id => id.toString()),
      ...(email.bcc || []).map(id => id.toString()),
    ];
    if (!authorizedUsers.includes(userId)) {
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
      $or: [{ to: userId }, { from: userId }, { cc: userId }, { bcc: userId }],
      labels: labelName,
    };
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