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
  bool _isDrawerOpen = false;
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            setState(() {
              _isDrawerOpen = !_isDrawerOpen;
            });
          },
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
                        icon: const Icon(Icons.filter_alt_outlined),
                        tooltip: 'Advanced search',
                        onPressed: _openAdvancedSearch,
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
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _openCompose();
                },
                icon: const Icon(Icons.edit, color: Colors.black87),
                label: const Text('Compose', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffeaf1fb),
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.inbox),
            label: Text('Inbox'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.star),
            label: Text('Starred'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.send),
            label: Text('Sent'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.drafts),
            label: Text('Drafts'),
          ),
          if (_selectedIndex == 3 && _drafts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 8, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_drafts.length, (i) {
                  final draft = _drafts[i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      draft['subject']?.isNotEmpty == true ? draft['subject'] : '(No subject)',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      draft['to']?.isNotEmpty == true ? draft['to'] : '(No recipient)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () => _openDraft(i),
                  );
                }),
              ),
            ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Labels',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.label, color: Colors.grey),
            title: const Text('Important'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.label, color: Colors.grey),
            title: const Text('Work'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.label, color: Colors.grey),
            title: const Text('Personal'),
            onTap: () {},
          ),
        ],
      ),
      body: Row(
        children: [
          if (_isDrawerOpen)
            NavigationRail(
              extended: true,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.inbox),
                  label: Text('Inbox'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.star),
                  label: Text('Starred'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.send),
                  label: Text('Sent'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.drafts),
                  label: Text('Drafts'),
                ),
              ],
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          Expanded(
            child: Column(
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
                      return EmailListItem(
                        sender: email['sender'],
                        subject: email['subject'],
                        preview: email['preview'],
                        time: email['time'],
                        isRead: email['isRead'],
                        isStarred: email['isStarred'],
                        onTap: () => _openEmailDetails(_emails.indexOf(email)),
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
                      );
                    },
                  ),
                ),
              ],
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