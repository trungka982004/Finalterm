const express = require('express');
const axios = require('axios');
const router = express.Router();

router.post('/verify', async (req, res) => {
  const { token } = req.body;
  try {
    const response = await axios.post(
      `https://www.google.com/recaptcha/api/siteverify?secret=${process.env.RECAPTCHA_SECRET_KEY}&response=${token}`
    );
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;