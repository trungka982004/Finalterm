import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:image_picker/image_picker.dart';
import '../services/email_service.dart';
import '../main.dart'; // Import for ThemeProvider

class ComposeScreen extends StatefulWidget {
  final List<String>? initialRecipients;
  final String? initialSubject;
  final String? initialBody;

  const ComposeScreen({
    super.key,
    this.initialRecipients,
    this.initialSubject,
    this.initialBody,
  });

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> with TickerProviderStateMixin {
  final _recipientsController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _htmlEditorController = HtmlEditorController();
  List<XFile> _attachments = [];
  bool _showCcBcc = false;
  bool _isLoading = false;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipients != null) {
      _recipientsController.text = widget.initialRecipients!.join(', ');
    }
    if (widget.initialSubject != null) {
      _subjectController.text = widget.initialSubject!;
    }
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recipientsController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _attachments.add(file));
    }
  }

  Future<void> _sendEmail() async {
    if (_recipientsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter at least one recipient.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    final emailService = Provider.of<EmailService>(context, listen: false);
    try {
      final htmlContent = await _htmlEditorController.getText();
      await emailService.sendEmail(
        recipients: _recipientsController.text.split(',').map((e) => e.trim()).toList(),
        cc: _ccController.text.isNotEmpty
            ? _ccController.text.split(',').map((e) => e.trim()).toList()
            : null,
        bcc: _bccController.text.isNotEmpty
            ? _bccController.text.split(',').map((e) => e.trim()).toList()
            : null,
        subject: _subjectController.text,
        body: htmlContent,
        attachments: _attachments,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email sent successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send email: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);
    final emailService = Provider.of<EmailService>(context, listen: false);
    try {
      final htmlContent = await _htmlEditorController.getText();
      await emailService.saveDraft(
        recipients: _recipientsController.text.isNotEmpty
            ? _recipientsController.text.split(',').map((e) => e.trim()).toList()
            : null,
        cc: _ccController.text.isNotEmpty
            ? _ccController.text.split(',').map((e) => e.trim()).toList()
            : null,
        bcc: _bccController.text.isNotEmpty
            ? _bccController.text.split(',').map((e) => e.trim()).toList()
            : null,
        subject: _subjectController.text.isNotEmpty ? _subjectController.text : null,
        body: htmlContent.isNotEmpty ? htmlContent : null,
        attachments: _attachments,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Draft saved successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Compose Email',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 2,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              ScaleTransition(
                scale: _buttonScaleAnimation,
                child: IconButton(
                  icon: Icon(Icons.save, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _buttonAnimationController.forward().then((_) {
                            _buttonAnimationController.reverse();
                            _saveDraft();
                          });
                        },
                  tooltip: 'Save Draft',
                ),
              ),
              ScaleTransition(
                scale: _buttonScaleAnimation,
                child: IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isLoading ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          _buttonAnimationController.forward().then((_) {
                            _buttonAnimationController.reverse();
                            _sendEmail();
                          });
                        },
                  tooltip: 'Send Email',
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Message',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _recipientsController,
                        decoration: InputDecoration(
                          labelText: 'To',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          hintText: 'Enter recipient email addresses',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showCcBcc ? Icons.expand_less : Icons.expand_more,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => setState(() => _showCcBcc = !_showCcBcc),
                          ),
                        ),
                      ),
                      if (_showCcBcc) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ccController,
                          decoration: InputDecoration(
                            labelText: 'Cc',
                            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            hintText: 'Enter Cc email addresses',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _bccController,
                          decoration: InputDecoration(
                            labelText: 'Bcc',
                            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            hintText: 'Enter Bcc email addresses',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1, color: Colors.grey),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          hintText: 'Enter email subject',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: HtmlEditor(
                          controller: _htmlEditorController,
                          htmlEditorOptions: HtmlEditorOptions(
                            hint: 'Type your message here...',
                            shouldEnsureVisible: true,
                          ),
                          callbacks: Callbacks(
                            onInit: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (widget.initialBody != null && widget.initialBody!.isNotEmpty) {
                                  final newBody = '<p><br></p><p><br></p>${widget.initialBody!}';
                                  _htmlEditorController.setText(newBody);
                                }
                              });
                            },
                          ),
                          htmlToolbarOptions: const HtmlToolbarOptions(
                            toolbarPosition: ToolbarPosition.aboveEditor,
                            defaultToolbarButtons: [
                              StyleButtons(),
                              FontButtons(),
                              ColorButtons(),
                              ListButtons(),
                              ParagraphButtons(),
                              InsertButtons(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _attachments
                            .map((file) => Chip(
                                  label: Text(
                                    file.name,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  deleteIcon: Icon(Icons.close, color: Theme.of(context).colorScheme.onError),
                                  onDeleted: () {
                                    setState(() => _attachments.remove(file));
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      ScaleTransition(
                        scale: _buttonScaleAnimation,
                        child: IconButton(
                          icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _buttonAnimationController.forward().then((_) {
                                    _buttonAnimationController.reverse();
                                    _pickAttachment();
                                  });
                                },
                          tooltip: 'Attach File',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}