import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class ComposeMailDialog extends StatefulWidget {
  final String? to;
  final String? subject;
  final String? body;
  final void Function(Map<String, dynamic> draft)? onDraft;
  const ComposeMailDialog({super.key, this.to, this.subject, this.body, this.onDraft});

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
    _quillController = widget.body != null && widget.body!.isNotEmpty
        ? quill.QuillController(
            document: quill.Document()..insert(0, widget.body!),
            selection: const TextSelection.collapsed(offset: 0),
          )
        : quill.QuillController.basic();
    _toController.text = widget.to ?? '';
    _subjectController.text = widget.subject ?? '';
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
    if (!_sent && widget.onDraft != null) {
      final draft = {
        'to': _toController.text,
        'subject': _subjectController.text,
        'body': _quillController.document.toPlainText(),
      };
      if (draft['to']!.isNotEmpty || draft['subject']!.isNotEmpty || draft['body']!.trim().isNotEmpty) {
        widget.onDraft!(draft);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24, top: 80),
      backgroundColor: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          width: 540,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xfff5f7fa),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                ),
                child: Row(
                  children: [
                    const Text('New Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      tooltip: 'Minimize',
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_full, size: 18),
                      tooltip: 'Fullscreen',
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Recipient Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _toController,
                        decoration: const InputDecoration(
                          hintText: 'To',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showCc = !_showCc),
                      child: Text('Cc', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _showBcc = !_showBcc),
                      child: Text('Bcc', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              if (_showCc)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: TextField(
                    controller: _ccController,
                    decoration: const InputDecoration(
                      hintText: 'Cc',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              if (_showBcc)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: TextField(
                    controller: _bccController,
                    decoration: const InputDecoration(
                      hintText: 'Bcc',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              // Subject Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    hintText: 'Subject',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: quill.QuillEditor.basic(
                    controller: _quillController,
                    config: const quill.QuillEditorConfig(),
                  ),
                ),
              ),
              if (_attachments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: List.generate(_attachments.length, (index) {
                      final file = _attachments[index];
                      return Chip(
                        label: Text(file.name),
                        onDeleted: () => _removeAttachment(index),
                        avatar: const Icon(Icons.attach_file, size: 18),
                      );
                    }),
                  ),
                ),
              // Bottom Toolbar & Action Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Send button and dropdown
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _sent = true;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      child: const Text('Send'),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: () {},
                      tooltip: 'More send options',
                    ),
                    // Toolbar icons
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _pickFiles,
                      tooltip: 'Attach files',
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_bold),
                      onPressed: () {},
                      tooltip: 'Formatting',
                    ),
                    IconButton(
                      icon: const Icon(Icons.insert_emoticon),
                      onPressed: () {},
                      tooltip: 'Emoji',
                    ),
                    IconButton(
                      icon: const Icon(Icons.link),
                      onPressed: () {},
                      tooltip: 'Insert link',
                    ),
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: () {},
                      tooltip: 'Insert image',
                    ),
                    IconButton(
                      icon: const Icon(Icons.lock),
                      onPressed: () {},
                      tooltip: 'Confidential mode',
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {},
                      tooltip: 'Pen',
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {},
                      tooltip: 'More',
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Discard',
                    ),
                  ],
                ),
              ),
              // Formatting toolbar (moved to bottom, below action row)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                child: quill.QuillSimpleToolbar(
                  controller: _quillController,
                  config: const quill.QuillSimpleToolbarConfig(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
} 