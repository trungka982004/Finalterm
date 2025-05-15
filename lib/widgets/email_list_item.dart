import 'package:flutter/material.dart';

class EmailListItem extends StatelessWidget {
  final String sender;
  final String subject;
  final String preview;
  final String time;
  final bool isRead;
  final bool isStarred;
  final VoidCallback? onTap;
  final VoidCallback? onReply;
  final VoidCallback? onForward;

  const EmailListItem({
    super.key,
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    this.isRead = false,
    this.isStarred = false,
    this.onTap,
    this.onReply,
    this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.blue[50],
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      color: isStarred ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () {
                      // Handle star/unstar
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sender,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  // Reply/Forward actions
                  Row(
                    children: [
                      if (onReply != null)
                        IconButton(
                          icon: const Icon(Icons.reply, size: 18),
                          tooltip: 'Reply',
                          onPressed: onReply,
                        ),
                      if (onForward != null)
                        IconButton(
                          icon: const Icon(Icons.forward, size: 18),
                          tooltip: 'Forward',
                          onPressed: onForward,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 