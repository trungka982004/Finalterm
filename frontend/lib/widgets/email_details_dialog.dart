import 'package:flutter/material.dart';

class EmailDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> email;
  final List<String> labels;
  final int? emailIndex;

  const EmailDetailsDialog({
    super.key,
    required this.email,
    required this.labels,
    this.emailIndex,
  });

  @override
  State<EmailDetailsDialog> createState() => _EmailDetailsDialogState();
}

class _EmailDetailsDialogState extends State<EmailDetailsDialog> {
  late Map<String, dynamic> _email;
  late List<String> _selectedLabels;
  late int? _emailIndex;

  @override
  void initState() {
    super.initState();
    _email = Map<String, dynamic>.from(widget.email);
    _selectedLabels = List<String>.from(_email['labels'] ?? []);
    _emailIndex = widget.emailIndex;
  }

  void _toggleStar() {
    setState(() {
      _email['isStarred'] = !(_email['isStarred'] ?? false);
    });
  }

  void _toggleRead() {
    setState(() {
      _email['isRead'] = !(_email['isRead'] ?? false);
    });
  }

  void _moveToTrash() {
    Navigator.of(context).pop({'updatedEmail': null, 'emailIndex': _emailIndex});
  }

  void _toggleLabel(String label) {
    setState(() {
      if (_selectedLabels.contains(label)) {
        _selectedLabels.remove(label);
      } else {
        _selectedLabels.add(label);
      }
      _email['labels'] = _selectedLabels;
    });
  }

  void _replyEmail() {
    print('Reply to email: ${_email['subject']}');
    // TODO: Implement reply logic
    // You might open the compose dialog with pre-filled recipients/subject
  }

  void _forwardEmail() {
    print('Forward email: ${_email['subject']}');
    // TODO: Implement forward logic
    // You might open the compose dialog with the body content
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(_email['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                IconButton(
                  icon: Icon(_email['isStarred'] == true ? Icons.star : Icons.star_border, color: Colors.amber),
                  onPressed: _toggleStar,
                  tooltip: 'Star/Unstar',
                ),
                IconButton(
                  icon: Icon(_email['isRead'] == true ? Icons.mark_email_read : Icons.mark_email_unread),
                  onPressed: _toggleRead,
                  tooltip: 'Mark as Read/Unread',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _moveToTrash,
                  tooltip: 'Move to Trash',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop({'updatedEmail': _email, 'emailIndex': _emailIndex}),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('From: ${_email['sender'] ?? ''}'),
            if (_email['to'] != null) Text('To: ${_email['to']}'),
            if (_email['cc'] != null) Text('Cc: ${_email['cc']}'),
            Text('Date: ${_email['time'] ?? ''}'),
            const SizedBox(height: 8),
            if (_selectedLabels.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _selectedLabels.map((label) => Chip(label: Text(label))).toList(),
              ),
            Wrap(
              spacing: 8,
              children: widget.labels.map((label) {
                final selected = _selectedLabels.contains(label);
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => _toggleLabel(label),
                );
              }).toList(),
            ),
            const Divider(),
            Expanded(child: SingleChildScrollView(child: Text(_email['body'] ?? '', style: const TextStyle(fontSize: 16)))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _replyEmail,
                  icon: const Icon(Icons.reply),
                  label: const Text('Reply'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _forwardEmail,
                  icon: const Icon(Icons.forward),
                  label: const Text('Forward'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text('ID: ${_email['id'] ?? 'N/A'}'),
                // Add more metadata as needed
              ],
            ),
          ],
        ),
      ),
    );
  }
} 