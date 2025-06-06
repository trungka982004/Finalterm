const mongoose = require('mongoose');

const emailSchema = new mongoose.Schema({
  sender: { type: String, required: true }, // Email của người gửi
  recipients: [{ type: String, required: true }], // Email của người nhận (To)
  cc: [{ type: String }], // Email của người nhận CC
  bcc: [{ type: String }], // Email của người nhận BCC
  subject: { type: String, required: true },
  body: { type: String, required: true }, // Nội dung HTML từ WYSIWYG editor
  attachments: [{ 
    url: { type: String }, // URL từ Cloudinary
    filename: { type: String },
    size: { type: Number } // Kích thước tệp (byte)
  }],
  folder: { 
    type: String, 
    enum: ['inbox', 'sent', 'draft', 'starred', 'trash'], 
    default: 'inbox' 
  },
  labels: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Label' }], // Nhãn tùy chỉnh
  isRead: { type: Boolean, default: false },
  isStarred: { type: Boolean, default: false },
  sentAt: { type: Date, default: Date.now },
  draftSavedAt: { type: Date } // Thời gian lưu bản nháp
});

module.exports = mongoose.model('Email', emailSchema);