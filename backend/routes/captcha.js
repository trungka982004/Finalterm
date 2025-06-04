const express = require('express');
const axios = require('axios');
const router = express.Router();

router.post('/verify', async (req, res) => {
  const { token } = req.body;
  try {
    const response = await axios.post(
      `https://www.google.com/recaptcha/api/siteverify?secret=${process.env.RECAPTCHA_SECRET_KEY}&response=${token}`
    );
    if (!response.data.success) {
      return res.status(400).json({ error: 'Invalid reCAPTCHA v2 verification' });
    }
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;