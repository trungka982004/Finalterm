import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/email_service.dart';
import '../services/auth_service.dart';
import 'compose_screen.dart';
import '../main.dart'; // Import for ThemeProvider

class EmailDetailPage extends StatefulWidget {
  final String emailId;
  const EmailDetailPage({super.key, required this.emailId});

  @override
  State<EmailDetailPage> createState() => _EmailDetailPageState();
}

class _EmailDetailPageState extends State<EmailDetailPage> with TickerProviderStateMixin {
  Map<String, dynamic>? _email;
  bool _isLoading = true;
  String _errorMessage = '';

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchEmailDetails();
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchEmailDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final emailService = Provider.of<EmailService>(context, listen: false);
      final emailData = await emailService.getEmailById(widget.emailId);
      if (mounted) {
        setState(() {
          _email = emailData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load email. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEmail() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting...')));
      try {
        await Provider.of<EmailService>(context, listen: false).deleteEmailPermanently(widget.emailId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email permanently deleted'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete email: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error));
        }
      }
    }
  }

  Future<void> _archiveEmail() async {
    if (_email == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archiving...')));
    try {
      await Provider.of<EmailService>(context, listen: false).moveToTrash(widget.emailId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email archived'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to archive email: ${e.toString()}'), backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildBody(),
          ),
          bottomNavigationBar: _isLoading || _errorMessage.isNotEmpty
              ? null
              : _EmailActionToolbar(
                  onReply: _handleReply,
                  onReplyAll: _handleReplyAll,
                  onForward: _handleForward,
                ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _SkeletonLoader();
    }
    if (_errorMessage.isNotEmpty) {
      return _ErrorView(message: _errorMessage, onRetry: _fetchEmailDetails);
    }
    if (_email == null) {
      return _ErrorView(message: 'Email data is unavailable.', onRetry: _fetchEmailDetails);
    }
    
    return CustomScrollView(
      slivers: [
        _EmailAppBar(
          email: _email!,
          onArchive: _archiveEmail,
          onDelete: _deleteEmail,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EmailHeader(email: _email!),
                const SizedBox(height: 24),
                _EmailBody(email: _email!),
                const SizedBox(height: 24),
                if (_email!['attachments'] != null && (_email!['attachments'] as List).isNotEmpty)
                  _AttachmentSection(attachments: _email!['attachments']),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildQuotedBody() {
    if (_email == null) return '';
    final sender = _email!['sender'] ?? 'N/A';
    final sentDate = _formatDetailDateTime(_email!['sentAt']);
    final originalBody = _email!['body'] ?? '';
    return '<br><br><hr><p style="color:#5f6368;">On $sentDate, $sender wrote:<blockquote style="margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex">$originalBody</blockquote></p>';
  }

  void _handleReply() {
    if (_email == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => ComposeScreen(initialRecipients: [_email!['sender']], initialSubject: 'Re: ${_email!['subject']}', initialBody: _buildQuotedBody())));
  }

  void _handleReplyAll() {
    if (_email == null) return;
    final currentUserEmail = Provider.of<AuthService>(context, listen: false).user?.email?.toLowerCase();
    final allRecipients = <String>{
      if (_email!['sender'] != null) (_email!['sender'] as String).toLowerCase(),
      ...(_email!['recipients'] as List? ?? []).map((e) => e.toString().toLowerCase()),
      ...(_email!['cc'] as List? ?? []).map((e) => e.toString().toLowerCase()),
    };
    if (currentUserEmail != null) allRecipients.remove(currentUserEmail);
    Navigator.push(context, MaterialPageRoute(builder: (context) => ComposeScreen(initialRecipients: allRecipients.toList(), initialSubject: 'Re: ${_email!['subject']}', initialBody: _buildQuotedBody())));
  }

  void _handleForward() {
    if (_email == null) return;
    final originalBody = _buildQuotedBody().replaceFirst('wrote:', 'wrote: <br>---------- Forwarded message ---------');
    Navigator.push(context, MaterialPageRoute(builder: (context) => ComposeScreen(initialSubject: 'Fwd: ${_email!['subject']}', initialBody: originalBody)));
  }

  String _formatDetailDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    return DateFormat('E, d MMM y, h:mm a').format(DateTime.parse(dateString).toLocal());
  }
}

class _EmailAppBar extends StatelessWidget {
  final Map<String, dynamic> email;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _EmailAppBar({required this.email, required this.onArchive, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      title: Text(email['subject'] ?? '(No Subject)', maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(icon: const Icon(Icons.archive_outlined), tooltip: 'Archive', onPressed: onArchive),
        IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: onDelete),
        PopupMenuButton<String>(
          tooltip: 'More options',
          itemBuilder: (context) => [const PopupMenuItem(value: 'mark_unread', child: Text('Mark as Unread'))],
        ),
      ],
    );
  }
}

class _EmailHeader extends StatelessWidget {
  final Map<String, dynamic> email;
  const _EmailHeader({required this.email});

  String _formatDetailDateTime(String? dateString) {
    if (dateString == null) return 'N/A';
    return DateFormat('E, d MMM y, h:mm a').format(DateTime.parse(dateString).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final sender = email['sender'] ?? 'Unknown Sender';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(sender.substring(0, 1).toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sender, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                'to ${email['recipients']?.join(', ') ?? 'me'}',
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          _formatDetailDateTime(email['sentAt']),
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmailBody extends StatelessWidget {
  final Map<String, dynamic> email;
  const _EmailBody({required this.email});

  Future<void> _launchUrl(String? url, BuildContext context) async {
    if (url == null) return;
    try {
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Html(
      data: email['body'] ?? '',
      style: {
        "body": Style(fontSize: FontSize(16.0), lineHeight: LineHeight.em(1.5)),
        "a": Style(color: Theme.of(context).colorScheme.primary),
      },
      onLinkTap: (url, _, __) => _launchUrl(url, context),
    );
  }
}

class _AttachmentSection extends StatelessWidget {
  final List attachments;
  const _AttachmentSection({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text('Attachments (${attachments.length})', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: attachments.map((att) => _AttachmentChip(attachment: att)).toList(),
        ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Map<String, dynamic> attachment;
  const _AttachmentChip({required this.attachment});

  Future<void> _launchUrl(String? url, BuildContext context) async {
    if (url == null) return;
    try {
      if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) throw Exception('Could not launch $url');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Theme.of(context).colorScheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sizeInKb = ((attachment['size'] ?? 0) / 1024).toStringAsFixed(1);

    return InkWell(
      onTap: () => _launchUrl(attachment['url'], context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_outlined, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(attachment['filename'] ?? 'attachment', maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('$sizeInKb KB', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmailActionToolbar extends StatelessWidget {
  final VoidCallback onReply;
  final VoidCallback onReplyAll;
  final VoidCallback onForward;

  const _EmailActionToolbar({required this.onReply, required this.onReplyAll, required this.onForward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0).copyWith(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(context, icon: Icons.reply_outlined, label: 'Reply', onPressed: onReply),
          _buildActionButton(context, icon: Icons.reply_all_outlined, label: 'Reply All', onPressed: onReplyAll),
          _buildActionButton(context, icon: Icons.forward_outlined, label: 'Forward', onPressed: onForward),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _SkeletonLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceVariant,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text(''), pinned: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 150, height: 16, color: Theme.of(context).colorScheme.surface),
                            const SizedBox(height: 8),
                            Container(width: 200, height: 12, color: Theme.of(context).colorScheme.surface),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(width: double.infinity, height: 14, color: Theme.of(context).colorScheme.surface),
                  const SizedBox(height: 12),
                  Container(width: double.infinity, height: 14, color: Theme.of(context).colorScheme.surface),
                  const SizedBox(height: 12),
                  Container(width: MediaQuery.of(context).size.width * 0.7, height: 14, color: Theme.of(context).colorScheme.surface),
                  const SizedBox(height: 24),
                  Container(width: double.infinity, height: 14, color: Theme.of(context).colorScheme.surface),
                  const SizedBox(height: 12),
                  Container(width: MediaQuery.of(context).size.width * 0.8, height: 14, color: Theme.of(context).colorScheme.surface),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: onRetry,
            )
          ],
        ),
      ),
    );
  }
}