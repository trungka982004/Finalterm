import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/email_service.dart';

class AutoReplyPage extends StatefulWidget {
  const AutoReplyPage({super.key});

  @override
  State<AutoReplyPage> createState() => _AutoReplyPageState();
}

class _AutoReplyPageState extends State<AutoReplyPage> {
  bool _enabled = false;
  final _messageController = TextEditingController();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _saveAutoReply() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final emailService = Provider.of<EmailService>(context, listen: false);
    try {
      await emailService.setAutoReply(
        _enabled,
        _messageController.text.isNotEmpty ? _messageController.text : null,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auto reply settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Reply Settings'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Enable Auto Reply',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: _enabled,
                    onChanged: (val) => setState(() => _enabled = val),
                    activeColor: theme.colorScheme.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Auto Reply Message',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your auto reply message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (_enabled && (value == null || value.isEmpty)) {
                        return 'Please enter an auto reply message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : FilledButton(
                              onPressed: _saveAutoReply,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(200, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save Settings',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}