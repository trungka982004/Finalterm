const mongoose = require('mongoose');

const emailSchema = new mongoose.Schema({
  from: { type: String, required: true },
  to: { type: String, required: true },
  cc: { type: String, default: '' },
  bcc: { type: String, default: '' },
  subject: { type: String, required: true },
  body: { type: String, required: true },
  time: { type: String, required: true },
  isRead: { type: Boolean, default: false },
  isStarred: { type: Boolean, default: false },
  category: { type: String, default: 'inbox', enum: ['inbox', 'sent', 'draft', 'trash', 'archive'] },
  labels: [{ type: String }],
  hasAttachments: { type: Boolean, default: false },
  attachmentUrls: [{ type: String }],
  inReplyTo: { type: String, default: '' },
  forwardedFrom: { type: String, default: '' },
});

module.exports = mongoose.model('Email', emailSchema);