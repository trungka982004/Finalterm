import 'package:flutter/material.dart';
import '../widgets/email_list_item.dart';
import '../widgets/compose_mail_dialog.dart';
import '../widgets/email_details_dialog.dart';
import '../widgets/advanced_search_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class GmailHomePage extends StatefulWidget {
  const GmailHomePage({super.key});

  @override
  State<GmailHomePage> createState() => _GmailHomePageState();
}

class _GmailHomePageState extends State<GmailHomePage> {
  int _selectedIndex = 0;
  bool _showAllDrawerItems = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Advanced search filters
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _hasAttachment = false;
  String _searchIn = 'all'; // 'all', 'subject', 'sender', 'body'

  // Sample email data
  final List<Map<String, dynamic>> _emails = [
    {
      'sender': 'John Doe',
      'subject': 'Project Update',
      'preview': 'Hi team, I wanted to share the latest updates on our project...',
      'body': 'Hi team,\n\nI wanted to share the latest updates on our project...\n\nBest,\nJohn',
      'time': '10:30 AM',
      'isRead': false,
      'isStarred': true,
      'category': 'primary',
    },
    {
      'sender': 'Alice Smith',
      'subject': 'Meeting Tomorrow',
      'preview': 'Don\'t forget about our team meeting tomorrow at 2 PM...',
      'body': 'Don\'t forget about our team meeting tomorrow at 2 PM in the main conference room.',
      'time': '9:15 AM',
      'isRead': true,
      'isStarred': false,
      'category': 'primary',
    },
    {
      'sender': 'Tech Newsletter',
      'subject': 'Weekly Tech Digest',
      'preview': 'Here are the top tech stories of the week...',
      'body': 'Here are the top tech stories of the week...\n1. Flutter 3.0 Released\n2. Dart 2.18 Announced',
      'time': 'Yesterday',
      'isRead': true,
      'isStarred': false,
      'category': 'promotions',
    },
    {
      'sender': 'HR Department',
      'subject': 'Benefits Update',
      'preview': 'Important information about your health benefits...',
      'body': 'Important information about your health benefits...\nPlease review the attached documents.',
      'time': 'Yesterday',
      'isRead': false,
      'isStarred': false,
      'category': 'primary',
    },
  ];

  // Drafts storage
  final List<Map<String, dynamic>> _drafts = [];

  final List<String> _labels = ['Important', 'Work', 'Personal'];

  // Sidebar items
  final List<Map<String, dynamic>> _drawerItems = [
    {'icon': Icons.inbox, 'title': 'Inbox', 'trailing': '1,046'},
    {'icon': Icons.star, 'title': 'Starred'},
    {'icon': Icons.snooze, 'title': 'Snoozed'},
    {'icon': Icons.send, 'title': 'Sent'},
    {'icon': Icons.drafts, 'title': 'Drafts', 'trailing': '41'},
    {'icon': Icons.label_important, 'title': 'Important'},
    {'icon': Icons.chat, 'title': 'Chats'},
    {'icon': Icons.schedule, 'title': 'Scheduled'},
    {'icon': Icons.mail, 'title': 'All Mail'},
    {'icon': Icons.report, 'title': 'Spam', 'trailing': '8'},
    {'icon': Icons.delete, 'title': 'Trash'},
    {'icon': Icons.settings, 'title': 'Manage labels'},
    {'icon': Icons.add, 'title': 'Create new label'},
  ];

  // Add a list to track checked state for each email
  List<bool> _checkedEmails = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    // Initialize checked state for emails
    _checkedEmails = List<bool>.filled(_emails.length, false);
  }

  List<Map<String, dynamic>> get _filteredEmails {
    List<Map<String, dynamic>> filtered = _emails;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((email) {
        bool match = false;
        if (_searchIn == 'all' || _searchIn == 'subject') {
          match |= (email['subject']?.toLowerCase().contains(_searchQuery) ?? false);
        }
        if (_searchIn == 'all' || _searchIn == 'sender') {
          match |= (email['sender']?.toLowerCase().contains(_searchQuery) ?? false);
        }
        if (_searchIn == 'all' || _searchIn == 'body') {
          match |= (email['preview']?.toLowerCase().contains(_searchQuery) ?? false) ||
                   (email['body']?.toLowerCase().contains(_searchQuery) ?? false);
        }
        return match;
      }).toList();
    }
    if (_dateFrom != null) {
      filtered = filtered.where((email) {
        return true; // For now, skip date filter for demo
      }).toList();
    }
    if (_dateTo != null) {
      filtered = filtered.where((email) {
        return true; // For now, skip date filter for demo
      }).toList();
    }
    if (_hasAttachment) {
      filtered = filtered.where((email) => email['attachments'] == true).toList();
    }
    return filtered;
  }

  void _openCompose({String? to, String? subject, String? body, int? draftIndex}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ComposeMailDialog(
        to: to,
        subject: subject,
        body: body,
        onDraft: (draft) {
          setState(() {
            if (draftIndex != null) {
              _drafts[draftIndex] = draft;
            } else {
              _drafts.add(draft);
            }
          });
        },
      ),
    );
  }

  void _openDraft(int index) {
    final draft = _drafts[index];
    _openCompose(
      to: draft['to'],
      subject: draft['subject'],
      body: draft['body'],
      draftIndex: index,
    );
  }

  void _openEmailDetails(int index) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EmailDetailsDialog(
        email: _emails[index],
        labels: _labels,
      ),
    );
    if (result != null) {
      setState(() {
        _emails[index] = result;
      });
    }
  }

  void _openAdvancedSearch() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AdvancedSearchDialog(
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        hasAttachment: _hasAttachment,
        searchIn: _searchIn,
      ),
    );
    if (result != null) {
      setState(() {
        _dateFrom = result['dateFrom'];
        _dateTo = result['dateTo'];
        _hasAttachment = result['hasAttachment'];
        _searchIn = result['searchIn'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Image.network(
              'https://www.gstatic.com/images/branding/product/1x/gmail_48dp.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.email, color: Colors.red),
            ),
            const SizedBox(width: 8),
            const Text(
              'Gmail',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 24),
            // Responsive search bar
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'Search mail',
                              prefixIcon: const Icon(Icons.search, color: Colors.black54),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: Colors.black54),
                        onPressed: _openAdvancedSearch,
                        tooltip: 'Advanced search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {},
          ),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Text(
              'U',
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Image.network(
                    'https://www.gstatic.com/images/branding/product/1x/gmail_48dp.png',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.email, color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Gmail',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Show first 5 items, then More/Less, then the rest if expanded
            ..._buildDrawerListTiles(),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('Primary', Icons.inbox, true),
                        _buildCategoryChip('Social', Icons.people, false),
                        _buildCategoryChip('Promotions', Icons.local_offer, false),
                        _buildCategoryChip('Updates', Icons.info, false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEmails.length,
              itemBuilder: (context, index) {
                final email = _filteredEmails[index];
                // Find the original index in _emails to sync checked state
                final originalIndex = _emails.indexOf(email);
                return InkWell(
                  onTap: () => _openEmailDetails(originalIndex),
                  child: EmailListItem(
                    sender: email['sender'],
                    subject: email['subject'],
                    preview: email['preview'],
                    time: email['time'],
                    isRead: email['isRead'],
                    isStarred: email['isStarred'],
                    isChecked: _checkedEmails[originalIndex],
                    onChecked: (checked) {
                      setState(() {
                        _checkedEmails[originalIndex] = checked ?? false;
                      });
                    },
                    onReply: () {
                      _openCompose(
                        to: email['sender'],
                        subject: 'Re: ${email['subject']}',
                        body: '\n\nOn ${email['time']}, ${email['sender']} wrote:\n${email['body']}',
                      );
                    },
                    onForward: () {
                      _openCompose(
                        subject: 'Fwd: ${email['subject']}',
                        body: '\n\n---------- Forwarded message ----------\nFrom: ${email['sender']}\nDate: ${email['time']}\nSubject: ${email['subject']}\n\n${email['body']}',
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openCompose();
        },
        child: const Icon(Icons.edit),
      ),
    );
  }

  List<Widget> _buildDrawerListTiles() {
    List<Widget> tiles = [];
    int showCount = _showAllDrawerItems ? _drawerItems.length : 5;

    for (int i = 0; i < showCount; i++) {
      tiles.add(
        ListTile(
          leading: Icon(_drawerItems[i]['icon']),
          title: Text(_drawerItems[i]['title']),
          selected: _selectedIndex == i,
          onTap: () {
            setState(() => _selectedIndex = i);
            Navigator.pop(context);
          },
          trailing: _drawerItems[i]['trailing'] != null
              ? Text(_drawerItems[i]['trailing'], style: TextStyle(color: Colors.grey))
              : null,
        ),
      );
    }

    if (!_showAllDrawerItems) {
      tiles.add(
        ListTile(
          leading: const Icon(Icons.keyboard_arrow_down),
          title: const Text('More'),
          onTap: () {
            setState(() {
              _showAllDrawerItems = true;
            });
          },
        ),
      );
    } else {
      tiles.add(
        ListTile(
          leading: const Icon(Icons.keyboard_arrow_up),
          title: const Text('Less'),
          onTap: () {
            setState(() {
              _showAllDrawerItems = false;
            });
          },
        ),
      );
      // Add the rest of the items if expanded
      for (int i = 5; i < _drawerItems.length; i++) {
        tiles.add(
          ListTile(
            leading: Icon(_drawerItems[i]['icon']),
            title: Text(_drawerItems[i]['title']),
            selected: _selectedIndex == i,
            onTap: () {
              setState(() => _selectedIndex = i);
              Navigator.pop(context);
            },
            trailing: _drawerItems[i]['trailing'] != null
                ? Text(_drawerItems[i]['trailing'], style: TextStyle(color: Colors.grey))
                : null,
          ),
        );
      }
    }
    return tiles;
  }

  Widget _buildCategoryChip(String label, IconData icon, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          // Handle category selection
        },
      ),
    );
  }
} 