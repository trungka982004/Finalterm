const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const multer = require('multer');
const cloudinary = require('cloudinary').v2;
const User = require('../models/User');

// Cấu hình Multer
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const filetypes = /jpeg|jpg|png/;
    const mimetype = filetypes.test(file.mimetype);
    if (mimetype) return cb(null, true);
    cb(new Error('Only .jpg, .jpeg, .png files are allowed'));
  },
  limits: { fileSize: 5 * 1024 * 1024 } // 5MB
});

// Kiểm tra định dạng đầu vào
const validatePhone = (phone) => /^\+?[0-9]{10,12}$/.test(phone);
const validateEmail = (email) => /^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$/.test(email);
const validatePassword = (password) => password.length >= 8;
const checkPasswordStrength = (password) => {
  const strongRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return strongRegex.test(password) ? 'Strong' : 'Weak, add uppercase, number, and special character';
};

// Đăng ký
router.post('/register', async (req, res) => {
  const { phone, password, confirmPassword } = req.body;
  if (!validatePhone(phone)) return res.status(400).json({ error: 'Invalid phone number' });
  if (!validatePassword(password)) return res.status(400).json({ error: 'Password must be at least 8 characters' });
  if (password !== confirmPassword) return res.status(400).json({ error: 'Passwords do not match' });
  const strength = checkPasswordStrength(password);
  if (strength !== 'Strong') return res.status(400).json({ error: strength });

  try {
    const existingUser = await User.findOne({ phone });
    if (existingUser) return res.status(400).json({ error: 'Phone number already registered' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new User({ phone, password: hashedPassword });
    await user.save();

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Đăng nhập
router.post('/login', async (req, res) => {
  const { phone, password, otp } = req.body;
  if (!validatePhone(phone)) return res.status(400).json({ error: 'Invalid phone number' });

  try {
    const user = await User.findOne({ phone });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) return res.status(401).json({ error: 'Invalid password' });

    if (user.twoFactorEnabled && !otp) {
      if (!user.email) return res.status(400).json({ error: 'Email required for 2FA' });
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
      const otpExpires = Date.now() + 5 * 60 * 1000;
      await User.updateOne({ phone }, { otp: otpCode, otpExpires });

      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user: process.env.GMAIL_USER, pass: process.env.GMAIL_PASS }
      });
      await transporter.sendMail({
        from: process.env.GMAIL_USER,
        to: user.email,
        subject: 'Login OTP',
        text: `Your OTP is ${otpCode}. It expires in 5 minutes.`
      });
      return res.json({ message: 'OTP sent to your email' });
    }

    if (user.twoFactorEnabled && (otp !== user.otp || Date.now() > user.otpExpires)) {
      return res.status(401).json({ error: 'Invalid or expired OTP' });
    }

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, { expiresIn: '1h' });
    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Bật/tắt 2FA
router.post('/toggle-2fa', async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (!user.email || !user.isEmailVerified) return res.status(400).json({ error: 'Verified email required for 2FA' });
    user.twoFactorEnabled = !user.twoFactorEnabled;
    await user.save();
    res.json({ message: `Two-factor authentication ${user.twoFactorEnabled ? 'enabled' : 'disabled'}` });
  } catch (err) {
    console.error(err);
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Khôi phục mật khẩu
router.post('/forgot-password', async (req, res) => {
  const { phone } = req.body;
  if (!validatePhone(phone)) return res.status(400).json({ error: 'Invalid phone number' });

  try {
    const user = await User.findOne({ phone });
    if (!user || !user.email || !user.isEmailVerified) return res.status(404).json({ error: 'User or verified email not found' });

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpires = Date.now() + 5 * 60 * 1000;
    await User.updateOne({ phone }, { otp, otpExpires });

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: { user: process.env.GMAIL_USER, pass: process.env.GMAIL_PASS }
    });
    await transporter.sendMail({
      from: process.env.GMAIL_USER,
      to: user.email,
      subject: 'Password Reset OTP',
      text: `Your OTP is ${otp}. It expires in 5 minutes.`
    });
    res.json({ message: 'OTP sent to your email' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

router.post('/reset-password', async (req, res) => {
  const { phone, otp, newPassword, confirmPassword } = req.body;
  if (!validatePhone(phone)) return res.status(400).json({ error: 'Invalid phone number' });
  if (!validatePassword(newPassword)) return res.status(400).json({ error: 'Password must be at least 8 characters' });
  if (newPassword !== confirmPassword) return res.status(400).json({ error: 'Passwords do not match' });
  const strength = checkPasswordStrength(newPassword);
  if (strength !== 'Strong') return res.status(400).json({ error: strength });

  try {
    const user = await User.findOne({ phone });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.otp !== otp || Date.now() > user.otpExpires) {
      return res.status(401).json({ error: 'Invalid or expired OTP' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await User.updateOne({ phone }, { password: hashedPassword, otp: null, otpExpires: null });
    res.json({ message: 'Password reset successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Thay đổi mật khẩu
router.post('/change-password', async (req, res) => {
  const { phone, oldPassword, newPassword, confirmPassword } = req.body;
  if (!validatePhone(phone)) return res.status(400).json({ error: 'Invalid phone number' });
  if (!validatePassword(newPassword)) return res.status(400).json({ error: 'Password must be at least 8 characters' });
  if (newPassword !== confirmPassword) return res.status(400).json({ error: 'Passwords do not match' });
  const strength = checkPasswordStrength(newPassword);
  if (strength !== 'Strong') return res.status(400).json({ error: strength });

  try {
    const user = await User.findOne({ phone });
    if (!user) return res.status(404).json({ error: 'User not found' });

    const validPassword = await bcrypt.compare(oldPassword, user.password);
    if (!validPassword) return res.status(401).json({ error: 'Invalid old password' });

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await User.updateOne({ phone }, { password: hashedPassword });
    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Cập nhật hồ sơ
function uploadSingleMiddleware(req, res, next) {
  upload.single('picture')(req, res, err => {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ error: err.message });
    } else if (err) {
      return res.status(400).json({ error: err.message });
    }
    next();
  });
}

router.post('/update-profile', uploadSingleMiddleware, async (req, res) => {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
  });

  const { email, name } = req.body;
  if (!email || !validateEmail(email)) return res.status(400).json({ error: 'Valid email is required' });

  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    if (await User.findOne({ email, _id: { $ne: user._id } })) {
      return res.status(400).json({ error: 'Email already in use' });
    }

    let pictureUrl = user.picture;
    if (req.file) {
      try {
        const result = await new Promise((resolve, reject) => {
          const uploadStream = cloudinary.uploader.upload_stream(
            { folder: 'email_app_profiles' },
            (error, result) => error ? reject(error) : resolve(result)
          );
          uploadStream.end(req.file.buffer);
        });
        pictureUrl = result.secure_url;
      } catch (error) {
        console.error('Cloudinary upload error:', error.message, error.stack);
        return res.status(500).json({ error: 'Failed to upload picture', details: error.message });
      }
    }

    // Cập nhật email và đánh dấu là đã xác minh
    await User.updateOne(
      { _id: decoded.userId },
      { email, name: name || user.name, picture: pictureUrl, isEmailVerified: true }
    );
    res.json({ message: 'Profile updated successfully' });
  } catch (err) {
    console.error(err);
    if (err.name === 'TokenExpiredError') {
      res.status(401).json({ error: 'Token expired' });
    } else if (err.name === 'JsonWebTokenError') {
      res.status(401).json({ error: 'Invalid token' });
    } else {
      res.status(500).json({ error: 'Server error' });
    }
  }
});

// Lấy thông tin người dùng
router.get('/profile', async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId).select('phone email name picture twoFactorEnabled isEmailVerified');
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({
      phone: user.phone,
      email: user.email,
      name: user.name,
      picture: user.picture,
      twoFactorEnabled: user.twoFactorEnabled,
      isEmailVerified: user.isEmailVerified
    });
  } catch (err) {
    console.error(err);
    res.status(401).json({ error: 'Invalid token' });
  }
});

// Xác minh token
router.get('/verify-token', async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'No token provided' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ message: 'Token valid', email: user.email });
  } catch (err) {
    console.error(err);
    res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;