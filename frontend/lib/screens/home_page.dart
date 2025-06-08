import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/auth_service.dart';
import '../services/email_service.dart';
import 'compose_screen.dart';
import 'email_detail_page.dart';
import 'labels_page.dart';
import 'auto_reply_page.dart';
import 'profile_page.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Import for ThemeProvider

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  String _currentFolder = 'inbox';
  String? _currentLabelId;
  String? _currentLabelName;
  List<Map<String, dynamic>> _emails = [];
  List<Map<String, dynamic>> _labels = [];
  bool _isLoading = false;
  bool _isNavigating = false;
  late IO.Socket _socket;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isDisposed = false;
  bool _isSearching = false;
  String _keyword = '';
  String _from = '';
  String _to = '';
  bool _hasAttachment = false;
  DateTime? _startDate;
  DateTime? _endDate;
  late AnimationController _advancedPanelController;
  late Animation<Offset> _slideAnimation;
  bool _showAdvancedPanel = false;

  bool _showNotificationBanner = false;
  Map<String, dynamic>? _notificationData;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _fetchEmails();
    _fetchLabels();
    _initSocket();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _advancedPanelController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
        .animate(
      CurvedAnimation(
          parent: _advancedPanelController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _showNewEmailBanner(Map<String, dynamic> data) {
    if (mounted && !_isDisposed) {
      _notificationTimer?.cancel();
      setState(() {
        _notificationData = data;
        _showNotificationBanner = true;
      });
      _notificationTimer = Timer(const Duration(seconds: 5), () {
        _hideNewEmailBanner();
      });
      if (_currentFolder == 'inbox' &&
          _currentLabelId == null &&
          !_isSearching) {
        _fetchEmails();
      }
    }
  }

  void _hideNewEmailBanner() {
    if (mounted && !_isDisposed && _showNotificationBanner) {
      setState(() {
        _showNotificationBanner = false;
      });
      _notificationTimer?.cancel();
    }
  }

  Future<void> _fetchEmails() async {
    if (_isLoading || _isDisposed) return;
    setState(() {
      if (!_isDisposed) _isLoading = true;
    });
    final emailService = Provider.of<EmailService>(context, listen: false);
    try {
      final emails =
          await emailService.listEmails(_currentFolder, labelId: _currentLabelId);
      if (mounted && !_isDisposed) {
        setState(() {
          _emails = emails;
          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Failed to load emails: ${e.toString()}')));
      }
    }
  }

  Future<void> _fetchLabels() async {
    final emailService = Provider.of<EmailService>(context, listen: false);
    try {
      final labels = await emailService.getLabels();
      if (mounted && !_isDisposed) {
        setState(() {
          _labels = labels;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Failed to load labels: ${e.toString()}')));
      }
    }
  }

  Future<void> _searchEmails() async {
    if (_isLoading || _isDisposed) return;
    setState(() {
      if (!_isDisposed) _isLoading = true;
    });
    final emailService = Provider.of<EmailService>(context, listen: false);
    try {
      final emails = await emailService.searchEmails(
        keyword: _keyword.isNotEmpty ? _keyword : null,
        from: _from.isNotEmpty ? _from : null,
        to: _to.isNotEmpty ? _to : null,
        hasAttachment: _hasAttachment,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted && !_isDisposed) {
        setState(() {
          _emails = emails;
          _isLoading = true;
        });
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoading = false;
          });
          _animationController.forward(from: 0.0);
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
            content: Text('Failed to search emails: ${e.toString()}')));
      }
    }
  }

  Future<void> _reloadPage() async {
    if (_isLoading || _isDisposed || _isNavigating) return;
    setState(() {
      if (!_isDisposed) _isLoading = true;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.getProfile();
      await _fetchEmails();
      await _fetchLabels();
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
        _initSocket();
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Failed to reload: ${e.toString()}')));
        Future.delayed(Duration.zero, () {
          if (mounted && !_isDisposed && !_isNavigating) {
            _isNavigating = true;
            Navigator.pushReplacementNamed(context, '/login').then((_) {
              _isNavigating = false;
            });
          }
        });
      }
    }
  }

  void _initSocket() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user?.email == null) return;

    _socket = IO.io('https://gmail-backend-1-wlx4.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    _socket.connect();
    _socket.onConnect((_) {
      if (!_isDisposed) {
        _socket.emit('join', authService.user!.email);
      }
    });

    _socket.on('newEmail', (data) {
      _showNewEmailBanner(data);
    });
  }

  Future<void> _showLabelDialog(
      String emailId, List<dynamic> currentLabels) async {
    final emailService = Provider.of<EmailService>(context, listen: false);
    final selectedLabels =
        List<String>.from(currentLabels.map((label) => label['_id'].toString()));
    final tempSelectedLabels = List<String>.from(selectedLabels);

    if (!mounted || _isDisposed) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Labels'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _labels.map((label) {
                    final labelId = label['_id'].toString();
                    final isSelected = tempSelectedLabels.contains(labelId);
                    return CheckboxListTile(
                      title: Text(label['name']),
                      value: isSelected,
                      activeColor: Theme.of(context).colorScheme.primary,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelectedLabels.add(labelId);
                          } else {
                            tempSelectedLabels.remove(labelId);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      for (var labelId in tempSelectedLabels) {
                        if (!selectedLabels.contains(labelId)) {
                          await emailService.assignLabel(emailId, labelId, 'add');
                        }
                      }
                      for (var labelId in selectedLabels) {
                        if (!tempSelectedLabels.contains(labelId)) {
                          await emailService.assignLabel(
                              emailId, labelId, 'remove');
                        }
                      }
                      if (mounted && !_isDisposed) {
                        await _fetchEmails();
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          const SnackBar(content: Text('Labels updated')),
                        );
                      }
                    } catch (e) {
                      if (mounted && !_isDisposed) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Failed to update labels: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: Text('Apply', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleMarkAsRead(Map<String, dynamic> email, int index) async {
    final emailService = Provider.of<EmailService>(context, listen: false);
    final emailId = email['_id'];
    final currentStatus = email['isRead'] as bool;
    final newStatus = !currentStatus;

    setState(() {
      _emails[index]['isRead'] = newStatus;
    });

    try {
      await emailService.markRead(emailId, newStatus);
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(newStatus ? 'Marked as read.' : 'Marked as unread.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emails[index]['isRead'] = currentStatus;
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleMoveToTrash(Map<String, dynamic> email, int index) async {
    final emailService = Provider.of<EmailService>(context, listen: false);
    final emailId = email['_id'];
    final removedEmail = _emails[index];
    
    setState(() {
      _emails.removeAt(index);
    });

    try {
      await emailService.moveToTrash(emailId);
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: const Text('Email moved to trash.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emails.insert(index, removedEmail);
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _socket.dispose();
    _animationController.dispose();
    _advancedPanelController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  String _getDisplayAddress(Map<String, dynamic> email) {
    if (_currentFolder == 'sent' || _currentFolder == 'draft') {
      final recipients = email['recipients'] as List? ?? [];
      if (recipients.isEmpty) {
        return '(No Recipients)';
      }
      return 'To: ${recipients.join(', ')}';
    }
    return email['sender'] as String? ?? 'Unknown Sender';
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null) return '';
    final dateTime = DateTime.parse(dateString).toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0 && dateTime.day == now.day) {
      return DateFormat.jm().format(dateTime);
    } else if (difference.inDays < 7) {
      return DateFormat.E().format(dateTime);
    } else {
      return DateFormat.yMd().format(dateTime);
    }
  }

  Widget _buildNotificationBanner() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      top: _showNotificationBanner ? 10.0 : -100.0,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6.0,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(Icons.mark_email_unread_outlined, color: Theme.of(context).colorScheme.primary),
            title: Text(
              'New Email from: ${_notificationData?['sender'] ?? ''}',
              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${_notificationData?['subject'] ?? '(No subject)'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            trailing: IconButton(
              icon: Icon(Icons.close, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: _hideNewEmailBanner,
            ),
            onTap: () {
              _hideNewEmailBanner();
              _fetchEmails();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context); // Access ThemeProvider
    final user = authService.user;

    Widget body;
    if (user == null) {
      body = RefreshIndicator(
        onRefresh: _reloadPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _reloadPage,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentLabelId != null && !_isSearching)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Chip(
                        label: Text(_currentLabelName ?? 'Label'),
                        deleteIcon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
                        onDeleted: () {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _currentLabelId = null;
                              _currentLabelName = null;
                            });
                            _fetchEmails();
                          }
                        },
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  if (_isSearching &&
                      (_keyword.isNotEmpty ||
                          _from.isNotEmpty ||
                          _to.isNotEmpty ||
                          _hasAttachment ||
                          _startDate != null ||
                          _endDate != null))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (_keyword.isNotEmpty)
                            Chip(
                              label: Text('Keyword: $_keyword'),
                              deleteIcon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              onDeleted: () {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _keyword = '';
                                  });
                                  _searchEmails();
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          if (_from.isNotEmpty)
                            Chip(
                              label: Text('From: $_from'),
                              deleteIcon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              onDeleted: () {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _from = '';
                                  });
                                  _searchEmails();
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          if (_to.isNotEmpty)
                            Chip(
                              label: Text('To: $_to'),
                              deleteIcon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              onDeleted: () {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _to = '';
                                  });
                                  _searchEmails();
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          if (_hasAttachment)
                            Chip(
                              label: const Text('Has Attachment'),
                              deleteIcon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              onDeleted: () {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _hasAttachment = false;
                                  });
                                  _searchEmails();
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          if (_startDate != null)
                            Chip(
                              label: Text(
                                  'From: ${DateFormat.yMd().format(_startDate!)}'),
                              deleteIcon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              onDeleted: () {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _startDate = null;
                                  });
                                  _searchEmails();
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          if (_endDate != null)
                            Chip(
                              label: Text(
                                  'To: ${DateFormat.yMd().format(_endDate!)}'),
                              deleteIcon: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              onDeleted: () {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _endDate = null;
                                  });
                                  _searchEmails();
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          if (_keyword.isNotEmpty ||
                              _from.isNotEmpty ||
                              _to.isNotEmpty ||
                              _hasAttachment ||
                              _startDate != null ||
                              _endDate != null)
                            Chip(
                              label: const Text('Clear All'),
                              deleteIcon: Icon(Icons.clear, size: 18, color: Theme.of(context).colorScheme.onSurface),
                              onDeleted: () {
                                if (mounted && !_isDisposed) {
                                  setState(() {
                                    _isSearching = false;
                                    _keyword = '';
                                    _from = '';
                                    _to = '';
                                    _hasAttachment = false;
                                    _startDate = null;
                                    _endDate = null;
                                    _showAdvancedPanel = false;
                                  });
                                  _fetchEmails();
                                  _advancedPanelController.reverse();
                                }
                              },
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _emails.length,
                        itemBuilder: (context, index) {
                          final email = _emails[index];
                          return _buildEmailListItem(email, index);
                        },
                      ),
                    ),
                  ),
                  if (_emails.isEmpty && !_isLoading)
                    SizedBox(
                      height: MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          100,
                      child: Center(
                        child: Text('No emails found',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                      ),
                    ),
                ],
              ),
      );
    }

    return Consumer<ThemeProvider>( // Wrap with Consumer to react to theme changes
      builder: (context, themeProvider, child) {
        return Scaffold(
          key: _scaffoldMessengerKey,
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    decoration: InputDecoration(
                      hintText: 'Search emails...',
                      prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 10.0),
                    ),
                    controller: TextEditingController(text: _keyword),
                    onChanged: (value) {
                      if (mounted && !_isDisposed) {
                        setState(() {
                          _keyword = value;
                        });
                        _searchEmails();
                      }
                    },
                    onSubmitted: (_) => _searchEmails(),
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                    cursorColor: Theme.of(context).colorScheme.primary,
                  )
                : Text('Gmail',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600)),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 2,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onSurface),
                onPressed: _isNavigating || _isLoading
                    ? null
                    : () => Scaffold.of(context).openDrawer(),
              ),
            ),
            actions: [
              if (!_isSearching)
                IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _isNavigating || _isLoading
                      ? null
                      : () {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _isSearching = true;
                            });
                          }
                        },
                ),
              if (_isSearching)
                IconButton(
                  icon: Icon(
                      _showAdvancedPanel
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _isNavigating || _isLoading
                      ? null
                      : () {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _showAdvancedPanel = !_showAdvancedPanel;
                            });
                            if (_showAdvancedPanel) {
                              _advancedPanelController.forward();
                            } else {
                              _advancedPanelController.reverse();
                            }
                          }
                        },
                ),
              if (_isSearching)
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: _isNavigating || _isLoading
                      ? null
                      : () {
                          if (mounted && !_isDisposed) {
                            setState(() {
                              _isSearching = false;
                              _keyword = '';
                              _from = '';
                              _to = '';
                              _hasAttachment = false;
                              _startDate = null;
                              _endDate = null;
                              _showAdvancedPanel = false;
                            });
                            _fetchEmails();
                            _advancedPanelController.reverse();
                          }
                        },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: _isNavigating || _isLoading
                      ? null
                      : () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfilePage()));
                        },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        user?.picture != null ? NetworkImage(user!.picture!) : null,
                    child: user?.picture == null
                        ? Text(
                            user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(user, authService),
          body: Stack(
            children: [
              body,
              if (_isSearching && _showAdvancedPanel)
                AnimatedBuilder(
                  animation: _advancedPanelController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Theme.of(context).colorScheme.surface,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'From',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                                ),
                                controller: TextEditingController(text: _from),
                                onChanged: (value) {
                                  if (mounted && !_isDisposed) {
                                    setState(() {
                                      _from = value;
                                    });
                                    _searchEmails();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'To',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                                ),
                                controller: TextEditingController(text: _to),
                                onChanged: (value) {
                                  if (mounted && !_isDisposed) {
                                    setState(() {
                                      _to = value;
                                    });
                                    _searchEmails();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              CheckboxListTile(
                                title: Text('Has Attachment',
                                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                value: _hasAttachment,
                                activeColor: Theme.of(context).colorScheme.primary,
                                onChanged: (value) {
                                  if (mounted && !_isDisposed) {
                                    setState(() {
                                      _hasAttachment = value ?? false;
                                    });
                                    _searchEmails();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ListTile(
                                      title: Text(_startDate == null
                                          ? 'Start Date'
                                          : DateFormat.yMd().format(_startDate!),
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                      trailing: Icon(Icons.calendar_today,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      onTap: () async {
                                        if (mounted && !_isDisposed) {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                _startDate ?? DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _startDate = picked;
                                            });
                                            _searchEmails();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ListTile(
                                      title: Text(_endDate == null
                                          ? 'End Date'
                                          : DateFormat.yMd().format(_endDate!),
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                      trailing: Icon(Icons.calendar_today,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      onTap: () async {
                                        if (mounted && !_isDisposed) {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _endDate ?? DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (picked != null) {
                                            setState(() {
                                              _endDate = picked;
                                            });
                                            _searchEmails();
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              _buildNotificationBanner(),
            ],
          ),
          floatingActionButton: user == null
              ? null
              : FloatingActionButton(
                  onPressed: _isNavigating || _isLoading
                      ? null
                      : () {
                          Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => ComposeScreen()))
                              .then((_) {
                            if (mounted && !_isDisposed) {
                              _fetchEmails();
                            }
                          });
                        },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
                  tooltip: 'Compose',
                ),
        );
      },
    );
  }

  Drawer _buildDrawer(dynamic user, AuthService authService) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.name ?? 'User',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
            ),
            accountEmail:
                Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundImage:
                  user?.picture != null ? NetworkImage(user!.picture!) : null,
              child: user?.picture == null
                  ? Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                    )
                  : null,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceVariant],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            otherAccountsPictures: [
              IconButton(
                icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface),
                onPressed: _isNavigating || _isLoading
                    ? null
                    : () async {
                        await authService.logout();
                        if (mounted && !_isDisposed && !_isNavigating) {
                          _isNavigating = true;
                          Navigator.pushReplacementNamed(context, '/login')
                              .then((_) {
                            _isNavigating = false;
                          });
                        }
                      },
              ),
            ],
          ),
          _buildDrawerItem(Icons.inbox, 'Inbox', 'inbox'),
          _buildDrawerItem(Icons.send, 'Sent', 'sent'),
          _buildDrawerItem(Icons.drafts, 'Drafts', 'draft'),
          _buildDrawerItem(Icons.star, 'Starred', 'starred'),
          _buildDrawerItem(Icons.delete, 'Trash', 'trash'),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Labels',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._labels.map((label) => _buildLabelItem(label['_id'], label['name'])),
          ListTile(
            leading: Icon(Icons.label_outline, color: Theme.of(context).colorScheme.onSurface),
            title: Text('Manage Labels', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
            onTap: _isNavigating || _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    if (mounted && !_isDisposed) {
                      _isNavigating = true;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LabelsPage(
                            onLabelSelected: (labelId) {
                              if (mounted && !_isDisposed) {
                                setState(() {
                                  _currentLabelId = labelId;
                                  _currentLabelName = _labels.firstWhere(
                                      (label) =>
                                          label['_id'] == labelId)['name'];
                                  _currentFolder = 'inbox';
                                  _isSearching = false;
                                  _keyword = '';
                                  _from = '';
                                  _to = '';
                                  _hasAttachment = false;
                                  _startDate = null;
                                  _endDate = null;
                                });
                                _fetchEmails();
                              }
                            },
                          ),
                        ),
                      ).then((_) {
                        _isNavigating = false;
                        _fetchLabels();
                      });
                    }
                  },
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
          ListTile(
            leading: Icon(Icons.reply_all_outlined, color: Theme.of(context).colorScheme.onSurface),
            title: Text('Auto Reply', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
            onTap: _isNavigating || _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    if (mounted && !_isDisposed) {
                      _isNavigating = true;
                      Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AutoReplyPage()))
                          .then((_) {
                        _isNavigating = false;
                      });
                    }
                  },
          ),
          ListTile(
            leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.onSurface),
            title: Text('Change Password', style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
            onTap: _isNavigating || _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    if (mounted && !_isDisposed) {
                      _isNavigating = true;
                      Navigator.pushNamed(context, '/change-password').then((_) {
                        _isNavigating = false;
                      });
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String folderName) {
    final isSelected =
        _currentFolder == folderName && _currentLabelId == null && !_isSearching;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 15,
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: _isNavigating || _isLoading
          ? null
          : () {
              if (mounted && !_isDisposed) {
                setState(() {
                  _currentFolder = folderName;
                  _currentLabelId = null;
                  _currentLabelName = null;
                  _isSearching = false;
                  _keyword = '';
                  _from = '';
                  _to = '';
                  _hasAttachment = false;
                  _startDate = null;
                  _endDate = null;
                  _showAdvancedPanel = false;
                });
                _fetchEmails();
                Navigator.pop(context);
              }
            },
    );
  }

  Widget _buildLabelItem(String labelId, String labelName) {
    final isSelected = _currentLabelId == labelId && !_isSearching;
    return ListTile(
      leading: Icon(Icons.label, color: Theme.of(context).colorScheme.onSurface),
      title: Text(
        labelName,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 15,
          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      onTap: _isNavigating || _isLoading
          ? null
          : () {
              if (mounted && !_isDisposed) {
                setState(() {
                  _currentLabelId = labelId;
                  _currentLabelName = labelName;
                  _currentFolder = 'inbox';
                  _isSearching = false;
                  _keyword = '';
                  _from = '';
                  _to = '';
                  _hasAttachment = false;
                  _startDate = null;
                  _endDate = null;
                  _showAdvancedPanel = false;
                });
                _fetchEmails();
                Navigator.pop(context);
              }
            },
    );
  }

  Widget _buildEmailListItem(Map<String, dynamic> email, int index) {
    final bool isUnread = email['isRead'] == false;
    final String emailId = email['_id'];

    return Dismissible(
      key: Key(emailId),
      background: Container(
        color: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.mark_email_read_outlined, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 8),
            Text(
              isUnread ? 'Mark as Read' : 'Mark as Unread',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).colorScheme.error,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Move to Trash',
              style: TextStyle(color: Theme.of(context).colorScheme.onError, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onError),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _handleMarkAsRead(email, index);
          return false;
        } else {
          return true;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _handleMoveToTrash(email, index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isUnread ? Theme.of(context).colorScheme.primary.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.8)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            child: Text(
              (_getDisplayAddress(email).isNotEmpty ? _getDisplayAddress(email)[0] : '?').toUpperCase(),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _getDisplayAddress(email),
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDateTime(email['sentAt']),
                style: TextStyle(
                  fontSize: 12,
                  color: isUnread ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          subtitle: Text(
            email['subject'] as String? ?? '(No Subject)',
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
              color: isUnread ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              email['isStarred'] == true ? Icons.star : Icons.star_border,
              color: email['isStarred'] == true ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: _isNavigating || _isLoading
                ? null
                : () async {
                    final emailService = Provider.of<EmailService>(context, listen: false);
                    await emailService.starEmail(email['_id'], email['isStarred'] != true);
                    if (mounted && !_isDisposed) {
                      _fetchEmails();
                    }
                  },
          ),
          onTap: _isNavigating || _isLoading
              ? null
              : () {
                  if (mounted && !_isDisposed) {
                    _isNavigating = true;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmailDetailPage(emailId: email['_id']),
                      ),
                    ).then((_) {
                      _isNavigating = false;
                      if (mounted && !_isDisposed) {
                        _fetchEmails();
                      }
                    });
                  }
                },
          onLongPress: _isNavigating || _isLoading
              ? null
              : () {
                  if (mounted && !_isDisposed) {
                    _showLabelDialog(email['_id'], email['labels'] ?? []);
                  }
                },
        ),
      ),
    );
  }
}