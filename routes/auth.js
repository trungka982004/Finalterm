const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken'); // Keep for signing tokens
const speakeasy = require('speakeasy');
const User = require('../models/User');
const axios = require('axios');
const EmailJS = require('@emailjs/nodejs');
const router = express.Router();

// Import shared middleware and validation
const authenticateJWT = require('../utils/authMiddleware'); // Using shared middleware
const { isValidEmail } = require('../utils/validation'); // Using shared validation

// Note: authenticateJWT is now imported. If there was a local definition, it's replaced.

router.post('/register', async (req, res) => {
  const { name, phone, password, captchaToken } = req.body;
  try {
    const captchaResponse = await axios.post(
      `https://www.google.com/recaptcha/api/siteverify?secret=${process.env.RECAPTCHA_SECRET_KEY}&response=${captchaToken}`
    );
    if (!captchaResponse.data.success) {
      return res.status(400).json({ error: 'Invalid CAPTCHA' });
    }

    const existingUser = await User.findOne({ phone });
    if (existingUser) {
      return res.status(400).json({ error: 'Phone number already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ name, phone, password: hashedPassword });
    await user.save();

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ token, userId: user._id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/login', async (req, res) => {
  const { phone, password, captchaToken, twoFactorCode } = req.body;
  try {
    const captchaResponse = await axios.post(
      `https://www.google.com/recaptcha/api/siteverify?secret=${process.env.RECAPTCHA_SECRET_KEY}&response=${captchaToken}`
    );
    if (!captchaResponse.data.success) {
      return res.status(400).json({ error: 'Invalid CAPTCHA' });
    }

    const user = await User.findOne({ phone });
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    if (user.twoFactorEnabled) {
      if (!twoFactorCode) {
        return res.status(400).json({ error: 'Two-factor code required' });
      }
      const verified = speakeasy.totp.verify({
        secret: user.twoFactorSecret,
        encoding: 'base32',
        token: twoFactorCode,
      });
      if (!verified) {
        return res.status(400).json({ error: 'Invalid two-factor code' });
      }
    }

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ token, userId: user._id });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/enable-2fa', authenticateJWT, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const secret = speakeasy.generateSecret({ name: `EmailApp:${user.phone}` });
    user.twoFactorSecret = secret.base32;
    user.twoFactorEnabled = true;
    await user.save();

    res.json({ message: 'Two-factor authentication enabled', secret: secret.base32 });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/disable-2fa', authenticateJWT, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.twoFactorEnabled = false;
    user.twoFactorSecret = '';
    await user.save();

    res.json({ message: 'Two-factor authentication disabled' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/profile/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const user = await User.findById(userId).select('-password -twoFactorSecret -otp -otpExpires');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/profile/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  const { name, email } = req.body;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (name) user.name = name;
    if (email) {
      if (!isValidEmail(email)) return res.status(400).json({ error: 'Invalid email format' }); // isValidEmail still used here
      const existingUser = await User.findOne({ email, _id: { $ne: userId } });
      if (existingUser) return res.status(400).json({ error: 'Email already in use' });
      user.email = email;
    }
    await user.save();

    res.json({ message: 'Profile updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/change-avatar/:userId', authenticateJWT, async (req, res) => {
  const { userId } = req.params;
  const { avatarUrl } = req.body;
  if (req.user.userId !== userId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.avatar = avatarUrl;
    await user.save();

    const io = req.app.get('io');
    io.to(userId).emit('profileUpdated', { avatar: avatarUrl });

    res.json({ message: 'Avatar updated successfully' });
  } catch (error)
    {
    res.status(500).json({ error: error.message });
  }
});

router.post('/change-password', authenticateJWT, async (req, res) => {
  // Renamed req.body.userId to currentUserId to avoid confusion with req.user.userId
  const { userId: targetUserId, oldPassword, newPassword } = req.body;
  if (req.user.userId !== targetUserId) {
    return res.status(403).json({ error: 'Unauthorized access' });
  }
  try {
    const user = await User.findById(targetUserId);
    if (!user || !(await bcrypt.compare(oldPassword, user.password))) {
      return res.status(400).json({ error: 'Invalid old password' });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();
    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  if (!isValidEmail(email)) { // isValidEmail used here
    return res.status(400).json({ error: 'Invalid email format' });
  }
  try {
    const user = await User.findOne({ email });
    if (!user) {
      // To prevent user enumeration, consider a generic message even if email not found
      // return res.status(400).json({ error: 'Email not found' });
      return res.json({ message: 'If your email is in our system, OTP will be sent.' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    user.otp = otp;
    user.otpExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
    await user.save();

    await EmailJS.send(
      process.env.EMAILJS_SERVICE_ID,
      process.env.EMAILJS_TEMPLATE_ID,
      { otp, to_email: email }, // Ensure your EmailJS template uses these variables
      { publicKey: process.env.EMAILJS_USER_ID, privateKey: process.env.EMAILJS_PRIVATE_KEY } // privateKey if needed by your EmailJS setup
    );

    res.json({ message: 'OTP sent to email' });
  } catch (error) {
    console.error('Forgot password error:', error); // Log the actual error
    res.status(500).json({ error: 'Failed to send OTP. ' + error.message });
  }
});

router.post('/verify-otp', async (req, res) => {
  const { email, otp, newPassword } = req.body;
  if (!isValidEmail(email)) { // isValidEmail used here
    return res.status(400).json({ error: 'Invalid email format' });
  }
  try {
    const user = await User.findOne({ email, otp, otpExpires: { $gt: Date.now() } });
    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired OTP' });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    user.otp = undefined;
    user.otpExpires = undefined;
    await user.save();

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;