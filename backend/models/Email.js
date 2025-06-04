const mongoose = require('mongoose');

const emailSchema = new mongoose.Schema({
  from: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // User._id of sender
  to: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },   // User._id of primary recipient
  cc: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', default: [] }],    // Array of User._id
  bcc: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', default: [] }],   // Array of User._id
  subject: { type: String, required: true },
  body: { type: String, required: true },
  time: { type: String, required: true },
  isRead: { type: Boolean, default: false },
  isStarred: { type: Boolean, default: false },
  category: { type: String, default: 'inbox', enum: ['inbox', 'sent', 'draft', 'trash', 'archive', 'spam'] },
  labels: [{ type: String }],
  hasAttachments: { type: Boolean, default: false },
  attachmentUrls: [{ type: String }],
  inReplyTo: { type: mongoose.Schema.Types.ObjectId, ref: 'Email', default: '' }, // Email._id
  forwardedFrom: { type: mongoose.Schema.Types.ObjectId, ref: 'Email', default: '' }, // Email._id
});

// Add indexes for frequently queried fields
emailSchema.index({ from: 1, to: 1, category: 1, labels: 1 });

module.exports = mongoose.model('Email', emailSchema);