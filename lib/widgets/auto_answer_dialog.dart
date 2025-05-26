import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auto_answer_provider.dart';
import '../providers/theme_provider.dart';

class AutoAnswerDialog extends StatefulWidget {
  const AutoAnswerDialog({super.key});

  @override
  State<AutoAnswerDialog> createState() => _AutoAnswerDialogState();
}

class _AutoAnswerDialogState extends State<AutoAnswerDialog> {
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final autoAnswerProvider = Provider.of<AutoAnswerProvider>(context, listen: false);
    _messageController = TextEditingController(text: autoAnswerProvider.defaultMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final autoAnswerProvider = Provider.of<AutoAnswerProvider>(context);

    return AlertDialog(
      title: Text(
        'Customize Auto-Reply Message',
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customize your auto-reply message. You can use {sender} and {subject} as placeholders.',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter your auto-reply message',
              border: const OutlineInputBorder(),
              fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              filled: true,
            ),
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            autoAnswerProvider.updateMessage(_messageController.text);
            Navigator.pop(context);
          },
          child: Text(
            'Save',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.blue,
            ),
          ),
        ),
      ],
    );
  }
} 