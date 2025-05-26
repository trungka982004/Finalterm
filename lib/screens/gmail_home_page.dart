import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/email_view_provider.dart';
import '../widgets/email_list_item.dart';
import '../widgets/compose_mail_dialog.dart';
import '../widgets/email_details_dialog.dart';
import '../widgets/advanced_search_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'profile_page.dart';
import 'label_management_page.dart';
import 'settings_page.dart';

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

  // Email categories
  final List<Map<String, dynamic>> _emailCategories = [
    {
      'name': 'Inbox',
      'icon': Icons.inbox,
      'count': '1,046',
      'emails': [
        {
          'sender': 'John Doe',
          'subject': 'Project Update',
          'preview': 'Hi team, I wanted to share the latest updates...',
          'time': '10:30 AM',
          'isRead': false,
          'isStarred': true,
          'hasAttachment': true,
        },
        // Add more sample emails
      ],
    },
    {
      'name': 'Starred',
      'icon': Icons.star,
      'count': '12',
      'emails': [],
    },
    {
      'name': 'Snoozed',
      'icon': Icons.snooze,
      'count': '0',
      'emails': [],
    },
    {
      'name': 'Sent',
      'icon': Icons.send,
      'count': '0',
      'emails': [],
    },
    {
      'name': 'Drafts',
      'icon': Icons.drafts,
      'count': '41',
      'emails': [],
    },
    {
      'name': 'Important',
      'icon': Icons.label_important,
      'count': '0',
      'emails': [],
    },
    {
      'name': 'Chats',
      'icon': Icons.chat,
      'count': '0',
      'emails': [],
    },
    {
      'name': 'Scheduled',
      'icon': Icons.schedule,
      'count': '0',
      'emails': [],
    },
    {
      'name': 'All Mail',
      'icon': Icons.mail,
      'count': '0',
      'emails': [],
    },
    {
      'name': 'Spam',
      'icon': Icons.report,
      'count': '8',
      'emails': [],
    },
    {
      'name': 'Trash',
      'icon': Icons.delete,
      'count': '0',
      'emails': [],
    },
  ];

  // Advanced search filters
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _hasAttachment = false;
  String _searchIn = 'all'; // 'all', 'subject', 'sender', 'body'

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
    _checkedEmails = List<bool>.filled(_emailCategories.length, false);
  }

  List<Map<String, dynamic>> get _filteredEmails {
    if (_selectedIndex < 0 || _selectedIndex >= _emailCategories.length) {
      return [];
    }
    List<Map<String, dynamic>> filtered = _emailCategories[_selectedIndex]['emails'];
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
      filtered = filtered.where((email) => email['hasAttachment'] == true).toList();
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

  void _openEmailDetails(Map<String, dynamic> email) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EmailDetailsDialog(
        email: email,
        labels: _labels,
      ),
    );
    if (result != null) {
      setState(() {
        _emailCategories[_selectedIndex]['emails'][result['index']] = result;
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final emailViewProvider = Provider.of<EmailViewProvider>(context);
    final currentCategory = _selectedIndex >= 0 && _selectedIndex < _emailCategories.length
        ? _emailCategories[_selectedIndex]
        : _emailCategories[0]; // Default to Inbox if index is invalid

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 1,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Image.asset(
              'assets/gmail_logo.png',
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.email, color: Colors.red),
            ),
            const SizedBox(width: 8),
            Text(
              'Gmail',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 24),
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
                            color: themeProvider.isDarkMode
                                ? Colors.grey[800]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search mail',
                              hintStyle: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.black54,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.black54,
                        ),
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
            icon: Icon(
              Icons.settings,
              color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200],
            child: Image.asset(
              'assets/images/avatar-default.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.person, size: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
              ),
              child: Row(
                children: [
                  Image.network(
                    'https://www.gstatic.com/images/branding/product/1x/gmail_48dp.png',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.email, color: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gmail',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            ..._buildDrawerListTiles(themeProvider),
            const Divider(),
            // View Mode Toggle
            SwitchListTile(
              title: const Text('Detailed View'),
              subtitle: const Text('Show email previews and attachments'),
              secondary: Icon(
                emailViewProvider.isDetailedView
                    ? Icons.view_agenda
                    : Icons.view_list,
                color: emailViewProvider.isDetailedView
                    ? Colors.blue
                    : Colors.grey,
              ),
              value: emailViewProvider.isDetailedView,
              onChanged: (bool value) {
                emailViewProvider.toggleViewMode();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[800]!
                      : Colors.grey[300]!,
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
                return InkWell(
                  onTap: () => _openEmailDetails(email),
                  child: emailViewProvider.isDetailedView
                      ? _buildDetailedEmailItem(email)
                      : _buildBasicEmailItem(email),
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

  Widget _buildDetailedEmailItem(Map<String, dynamic> email) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: email['isStarred'] ? Colors.amber : Colors.grey,
          child: Text(
            email['sender'][0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          email['sender'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email['subject'],
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email['preview'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              email['time'],
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            if (email['hasAttachment'])
              Icon(
                Icons.attach_file,
                size: 16,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildBasicEmailItem(Map<String, dynamic> email) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: email['isStarred'] ? Colors.amber : Colors.grey,
        child: Text(
          email['sender'][0].toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        email['sender'],
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        email['subject'],
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
      trailing: Text(
        email['time'],
        style: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  List<Widget> _buildDrawerListTiles(ThemeProvider themeProvider) {
    List<Widget> tiles = [];
    int showCount = _showAllDrawerItems ? _emailCategories.length : 5;

    for (int i = 0; i < showCount; i++) {
      final category = _emailCategories[i];
      tiles.add(
        ListTile(
          leading: Icon(category['icon']),
          title: Text(category['name']),
          selected: _selectedIndex == i,
          onTap: () {
            setState(() => _selectedIndex = i);
            Navigator.pop(context);
          },
          trailing: category['count'] != null
              ? Text(category['count'], style: TextStyle(color: Colors.grey))
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
    }

    // Add Manage Labels section
    tiles.add(const Divider());
    tiles.add(
      ListTile(
        leading: const Icon(Icons.label),
        title: const Text('Manage Labels'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LabelManagementPage()),
          );
        },
      ),
    );

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