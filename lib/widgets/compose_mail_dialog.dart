import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ComposeMailDialog extends StatefulWidget {
  final String? to;
  final String? subject;
  final String? body;
  final Function(Map<String, dynamic>) onDraft;

  const ComposeMailDialog({
    super.key,
    this.to,
    this.subject,
    this.body,
    required this.onDraft,
  });

  @override
  State<ComposeMailDialog> createState() => _ComposeMailDialogState();
}

class _ComposeMailDialogState extends State<ComposeMailDialog> {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  bool _showCc = false;
  bool _showBcc = false;
  List<PlatformFile> _attachments = [];

  late quill.QuillController _quillController;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _toController.text = widget.to ?? '';
    _subjectController.text = widget.subject ?? '';
    _quillController = widget.body != null && widget.body!.isNotEmpty
        ? quill.QuillController(
            document: quill.Document()..insert(0, widget.body!),
            selection: const TextSelection.collapsed(offset: 0),
          )
        : quill.QuillController.basic();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _attachments.addAll(result.files);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  @override
  void dispose() {
    if (!_sent) {
      final draft = {
        'to': _toController.text,
        'subject': _subjectController.text,
        'body': _quillController.document.toPlainText(),
      };
      if (draft['to']!.isNotEmpty || draft['subject']!.isNotEmpty || draft['body']!.trim().isNotEmpty) {
        widget.onDraft(draft);
      }
    }
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Dialog(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  'New Message',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            // To Field
            TextField(
              controller: _toController,
              decoration: InputDecoration(
                labelText: 'To',
                border: const OutlineInputBorder(),
                fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                filled: true,
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Subject Field
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: const OutlineInputBorder(),
                fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                filled: true,
                labelStyle: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Quill Editor
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _quillController,
                    ),
                    Expanded(
                      child: Container(
                        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                        child: quill.QuillEditor(
                          controller: _quillController,
                          scrollController: ScrollController(),
                          focusNode: FocusNode(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onDraft({
                      'to': _toController.text,
                      'subject': _subjectController.text,
                      'body': _quillController.document.toPlainText(),
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save as Draft',
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implement send functionality
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.isDarkMode ? Colors.blue[700] : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 