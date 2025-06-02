const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  phone: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  email: { type: String, default: '' },
  avatar: { type: String, default: '' },
  autoAnswerEnabled: { type: Boolean, default: false },
  autoAnswerMessage: { type: String, default: 'Thank you for your email. I am currently using auto-reply mode.' },
  twoFactorEnabled: { type: Boolean, default: false },
  twoFactorSecret: { type: String, default: '' },
  notificationSettings: {
    type: {
      enabled: { type: Boolean, default: true },
      sound: { type: Boolean, default: true },
    },
    default: { enabled: true, sound: true },
  },
  otp: { type: String },
  otpExpires: { type: Number },
});

module.exports = mongoose.model('User', userSchema);