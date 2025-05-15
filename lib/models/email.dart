class Email {
  final String sender;
  final String subject;
  final String preview;
  final String body;
  final String time;
  bool isRead;
  bool isStarred;
  String category;
  List<String> labels;
  bool hasAttachments;
  String? id;

  Email({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.body,
    required this.time,
    this.isRead = false,
    this.isStarred = false,
    this.category = 'primary',
    List<String>? labels,
    this.hasAttachments = false,
    this.id,
  }) : labels = labels ?? [];

  factory Email.fromMap(Map<String, dynamic> map) {
    return Email(
      sender: map['sender'] ?? '',
      subject: map['subject'] ?? '',
      preview: map['preview'] ?? '',
      body: map['body'] ?? '',
      time: map['time'] ?? '',
      isRead: map['isRead'] ?? false,
      isStarred: map['isStarred'] ?? false,
      category: map['category'] ?? 'primary',
      labels: List<String>.from(map['labels'] ?? []),
      hasAttachments: map['attachments'] == true || map['hasAttachments'] == true,
      id: map['id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'subject': subject,
      'preview': preview,
      'body': body,
      'time': time,
      'isRead': isRead,
      'isStarred': isStarred,
      'category': category,
      'labels': labels,
      'attachments': hasAttachments,
      'id': id,
    };
  }
} 