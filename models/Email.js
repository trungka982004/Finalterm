const mongoose = require('mongoose');

const emailSchema = new mongoose.Schema({
  from: { type: String, required: true }, // Should store User._id of sender
  to: { type: String, required: true },   // Should store User._id of primary recipient
  cc: { type: String, default: '' },      // Should store comma-separated User._id strings if multiple
  bcc: { type: String, default: '' },     // Should store comma-separated User._id strings if multiple
  subject: { type: String, required: true },
  body: { type: String, required: true },
  time: { type: String, required: true },
  isRead: { type: Boolean, default: false },
  isStarred: { type: Boolean, default: false },
  category: { type: String, default: 'inbox', enum: ['inbox', 'sent', 'draft', 'trash', 'archive', 'spam'] }, // Added 'spam'
  labels: [{ type: String }],
  hasAttachments: { type: Boolean, default: false },
  attachmentUrls: [{ type: String }],
  inReplyTo: { type: String, default: '' }, // Email._id
  forwardedFrom: { type: String, default: '' }, // Email._id
});

module.exports = mongoose.model('Email', emailSchema);