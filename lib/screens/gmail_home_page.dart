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
          'isSelected': false,
          'category': 'Updates',
          'body': 'Hi team,\n\nI hope this email finds you well.\n\nI wanted to share the latest updates on the project. We have made significant progress on the frontend development, and the core components are now complete. The backend integration is also proceeding smoothly, and we expect to have the first phase of API connections established by the end of the week.\n\nNext steps include thorough testing of the integrated modules and beginning work on the user authentication system.\n\nPlease review the updated project documentation in the shared drive for more details.\n\nThanks,\nJohn',
        },
        {
          'sender': 'Alice Smith',
          'subject': 'Meeting Minutes',
          'preview': 'Please find the minutes from our meeting yesterday...',
          'time': 'Yesterday',
          'isRead': true,
          'isStarred': false,
          'hasAttachment': false,
          'isSelected': false,
          'category': 'Social',
          'body': 'Hi Team,\n\nPlease find the minutes from our meeting yesterday attached to this email. We discussed the upcoming team building event and finalized the venue and activities. Please RSVP by Friday so we can get a final headcount.\n\nLooking forward to seeing you all there!\n\nBest,\nAlice',
        },
        {
          'sender': 'Bob Johnson',
          'subject': 'Weekly Newsletter',
          'preview': 'Check out the latest news and updates...',
          'time': 'Mar 15',
          'isRead': false,
          'isStarred': false,
          'hasAttachment': true,
          'isSelected': false,
          'category': 'Promotions',
          'body': 'Subject: Your Weekly Digest of Awesome Deals!\n\nHi Subscriber,\n\nGet ready for our biggest sale of the year! This week only, enjoy up to 50% off on all our premium products. From gadgets to gizmos, we have something for everyone.\n\nVisit our website today to browse the deals and use code WEEKLYDEAL at checkout.\n\nHappy Shopping!\n\nThe Awesome Products Team',
        },
        {
          'sender': 'Charlie Brown',
          'subject': 'Important Announcement',
          'preview': 'Please read this important information...',
          'time': 'Mar 14',
          'isRead': true,
          'isStarred': true,
          'hasAttachment': false,
          'isSelected': false,
          'category': 'Updates',
          'body': 'Subject: Action Required: Important Security Update\n\nDear User,\n\nThis is an urgent notification regarding your account. We have detected unusual activity and require you to verify your login details immediately. Please click on the link below to secure your account:\n\n[Link to a fake login page - DO NOT CLICK]\n\nFailure to verify your account within 24 hours will result in temporary suspension.\n\nSincerely,\nYour Security Team',
        },
        {
          'sender': 'Diana Prince',
          'subject': 'Your Order Confirmation',
          'preview': 'Thank you for your order...',
          'time': 'Mar 14',
          'isRead': false,
          'isStarred': false,
          'hasAttachment': false,
          'isSelected': false,
          'category': 'Promotions',
          'body': 'Subject: Your Order #12345 Confirmed!\n\nDear Diana,\n\nThank you for your order! We are pleased to confirm your recent purchase. Your order #12345 has been received and is being processed.\n\nItems ordered:\n- Item A (Qty: 1)\n- Item B (Qty: 2)\n\nWe will send you another email with tracking information once your order has shipped.\n\nThank you for shopping with us!\n\nThe Store Team',
        },
        {
          'sender': 'Bruce Wayne',
          'subject': 'Action Required: Account Security',
          'preview': 'Please review your account activity...',
          'time': 'Mar 13',
          'isRead': false,
          'isStarred': true,
          'hasAttachment': true,
          'isSelected': false,
          'category': 'Updates',
          'body': 'Subject: Security Alert: Unusual Login Activity\n\nDear Bruce,\n\nWe have detected a login to your account from a new device at [IP Address] on [Date] at [Time]. If this was you, you can ignore this alert. If this was not you, please secure your account immediately by changing your password and reviewing your recent activity.\n\nVisit your security settings here: [Link to fake security page]\n\nSincerely,\nYour Account Security Team',
        },
        {
          'sender': 'Clark Kent',
          'subject': 'Team Lunch Invitation',
          'preview': 'Join us for lunch on Friday...',
          'time': 'Mar 13',
          'isRead': true,
          'isStarred': false,
          'hasAttachment': false,
          'isSelected': false,
          'category': 'Social',
          'body': '''Hi Team,

Just a friendly reminder about our team lunch this Friday at 1:00 PM at the usual spot. We'll be celebrating the successful completion of the recent project milestone.

Please let me know by end of day tomorrow if you can make it.

See you there!

Best,
Clark''',
        },
        // Add more sample emails
      ],
    },
    {
      'name': 'Starred',
      'icon': Icons.star,
      'count': '12',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Snoozed',
      'icon': Icons.snooze,
      'count': '0',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Sent',
      'icon': Icons.send,
      'count': '0',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Drafts',
      'icon': Icons.drafts,
      'count': '41',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Important',
      'icon': Icons.label_important,
      'count': '0',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Chats',
      'icon': Icons.chat,
      'count': '0',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Scheduled',
      'icon': Icons.schedule,
      'count': '0',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'All Mail',
      'icon': Icons.mail,
      'count': '0',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Spam',
      'icon': Icons.report,
      'count': '8',
      'emails': <Map<String, dynamic>>[],
    },
    {
      'name': 'Trash',
      'icon': Icons.delete,
      'count': '0',
      'emails': <Map<String, dynamic>>[],
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
  int? _hoveredEmailIndex; // Add state to track hovered email index
  int _selectedCategoryChipIndex = 0; // Add state to track selected category chip
  String _selectedFilterChipLabel = 'Primary'; // Add state for selected filter chip label

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    // Initialize checked state for emails based on the current category's emails
    // Ensure the emails list is treated as List<Map<String, dynamic>>
    final currentEmails = _emailCategories[_selectedIndex]['emails'];
    if (currentEmails is List) {
       _checkedEmails = List<bool>.filled(currentEmails.length, false);
    } else {
       _checkedEmails = [];
    }
  }

  @override
  void didUpdateWidget(covariant GmailHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset checked state when the selected category changes
     final currentEmails = _emailCategories[_selectedIndex]['emails'];
     if (currentEmails is List) {
       _checkedEmails = List<bool>.filled(currentEmails.length, false);
     } else {
       _checkedEmails = [];
     }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredEmails {
    if (_selectedIndex < 0 || _selectedIndex >= _emailCategories.length) {
      return [];
    }
    // Ensure the emails list is treated as List<Map<String, dynamic>>
    final dynamic categoryEmails = _emailCategories[_selectedIndex]['emails'];
    List<Map<String, dynamic>> emails = []; // Initialize as an empty list of the correct type

    if (categoryEmails is List) {
       // Iterate through the list and add elements that are maps of the correct type
       for (final item in categoryEmails) {
         if (item is Map<String, dynamic>) {
           emails.add(item);
         }
       }
    }

    // Apply filter based on selected category chip ONLY if the main category is Inbox
    if (_emailCategories[_selectedIndex]['name'] == 'Inbox') {
       if (_selectedFilterChipLabel != 'Primary') {
         emails = emails.where((email) => email['category'] == _selectedFilterChipLabel).toList();
       }
       // If 'Primary' is selected, no additional filtering is needed here as all Inbox emails are included initially.
    }

    if (_searchQuery.isNotEmpty) {
      emails = emails.where((email) {
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
      emails = emails.where((email) {
        return true; // For now, skip date filter for demo
      }).toList();
    }
    if (_dateTo != null) {
      emails = emails.where((email) {
        return true; // For now, skip date filter for demo
      }).toList();
    }
    if (_hasAttachment) {
      emails = emails.where((email) => email['hasAttachment'] == true).toList();
    }
    return emails;
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
    // Find the index of the email in the current category's list
    final emailIndex = _emailCategories[_selectedIndex]['emails'].indexOf(email);
    if (emailIndex == -1) return; // Should not happen if email comes from the list

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EmailDetailsDialog(
        email: email,
        labels: _labels,
        emailIndex: emailIndex,
      ),
    );
    if (result != null && result['emailIndex'] != null) {
      setState(() {
        // Update the email in the original list using the passed index
        // Handle case where email is deleted (result['updatedEmail'] is null)
        if (result['updatedEmail'] == null) {
          _emailCategories[_selectedIndex]['emails'].removeAt(result['emailIndex']);
           // Update checked state and hovered state after removing email
          if (_checkedEmails.length > result['emailIndex']) {
            _checkedEmails.removeAt(result['emailIndex']);
          }
          // Adjust hovered index if necessary
          if (_hoveredEmailIndex != null && _hoveredEmailIndex! >= result['emailIndex']) {
             _hoveredEmailIndex = _hoveredEmailIndex! > result['emailIndex'] ? _hoveredEmailIndex! - 1 : null;
          }
        } else {
           _emailCategories[_selectedIndex]['emails'][result['emailIndex']] = result['updatedEmail'];
        }
        // Re-initialize checked state if emails list size changes
         _checkedEmails = List<bool>.filled(_filteredEmails.length, false);
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

  void _toggleEmailSelection(int index, bool? value) {
    if (index >= 0 && index < _checkedEmails.length) {
      setState(() {
        _checkedEmails[index] = value ?? false;
      });
    }
  }

  void _toggleStar(int index) {
    // Find the corresponding email in the original list using the index in the filtered list
    final originalEmailIndex = _emailCategories[_selectedIndex]['emails'].indexOf(_filteredEmails[index]);
    if (originalEmailIndex != -1) {
      setState(() {
        _emailCategories[_selectedIndex]['emails'][originalEmailIndex]['isStarred'] =
            !(_emailCategories[_selectedIndex]['emails'][originalEmailIndex]['isStarred'] ?? false);
      });
    }
  }

  // Add methods for new actions
  void _archiveEmail(int index) {
    // Implement archive logic
    print('Archive email at index: $index');
     // For demo, remove the email from the list
     if (index >= 0 && index < _filteredEmails.length) {
       final originalEmailIndex = _emailCategories[_selectedIndex]['emails'].indexOf(_filteredEmails[index]);
       if(originalEmailIndex != -1) {
         setState(() {
           _emailCategories[_selectedIndex]['emails'].removeAt(originalEmailIndex);
            // Update checked state and hovered state after removing email
           if (_checkedEmails.length > index) {
             _checkedEmails.removeAt(index);
           }
           if (_hoveredEmailIndex != null && _hoveredEmailIndex! >= index) {
             _hoveredEmailIndex = _hoveredEmailIndex! > index ? _hoveredEmailIndex! - 1 : null;
           }
         });
       }
     }
  }

  void _deleteEmail(int index) {
    // Implement delete logic (move to Trash)
    print('Delete email at index: $index');
     // For demo, remove the email from the list
     if (index >= 0 && index < _filteredEmails.length) {
       final originalEmailIndex = _emailCategories[_selectedIndex]['emails'].indexOf(_filteredEmails[index]);
       if(originalEmailIndex != -1) {
         setState(() {
           _emailCategories[_selectedIndex]['emails'].removeAt(originalEmailIndex);
            // Update checked state and hovered state after removing email
           if (_checkedEmails.length > index) {
             _checkedEmails.removeAt(index);
           }
           if (_hoveredEmailIndex != null && _hoveredEmailIndex! >= index) {
             _hoveredEmailIndex = _hoveredEmailIndex! > index ? _hoveredEmailIndex! - 1 : null;
           }
         });
       }
     }
  }

  void _markAsRead(int index) {
    // Implement mark as read logic
    print('Mark as read email at index: $index');
     if (index >= 0 && index < _filteredEmails.length) {
       final originalEmailIndex = _emailCategories[_selectedIndex]['emails'].indexOf(_filteredEmails[index]);
       if(originalEmailIndex != -1) {
         setState(() {
           _emailCategories[_selectedIndex]['emails'][originalEmailIndex]['isRead'] = true;
         });
       }
     }
  }

  void _snoozeEmail(int index) {
    // Implement snooze logic
    print('Snooze email at index: $index');
    // For demo, do nothing
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final emailViewProvider = Provider.of<EmailViewProvider>(context);
    final currentCategory = _selectedIndex >= 0 && _selectedIndex < _emailCategories.length
        ? _emailCategories[_selectedIndex]
        : _emailCategories[0]; // Default to Inbox if index is invalid

    // Ensure _checkedEmails size matches _filteredEmails size
    if (_checkedEmails.length != _filteredEmails.length) {
      _checkedEmails = List<bool>.filled(_filteredEmails.length, false);
    }

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
                // Use the index from the filtered list to access the checked state
                final isChecked = _checkedEmails[index];
                final isHovered = _hoveredEmailIndex == index; // Check if current item is hovered

                return MouseRegion( // Wrap with MouseRegion to detect hover
                  onEnter: (_) => setState(() => _hoveredEmailIndex = index),
                  onExit: (_) => setState(() => _hoveredEmailIndex = null),
                  child: InkWell(
                    // Wrap the existing email item with Row for Checkbox and Star button
                    child: Row(
                      children: [
                        // Checkbox for selection
                        Checkbox(
                          value: isChecked,
                          onChanged: (bool? value) {
                            // Use the index from the filtered list to toggle selection
                            _toggleEmailSelection(index, value);
                          },
                          // Apply theme to checkbox
                          activeColor: themeProvider.isDarkMode ? Colors.blue[300] : Colors.blue,
                          checkColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
                        ),
                        Expanded(
                          // Wrap the existing email item content with Expanded
                          child: emailViewProvider.isDetailedView
                              ? _buildDetailedEmailItem(email, index) // Pass index to detailed item
                              : _buildBasicEmailItem(email, index), // Pass index to basic item
                        ),
                        if (isHovered) // Conditionally show icons when hovered
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.archive_outlined),
                                onPressed: () => _archiveEmail(index),
                                tooltip: 'Archive',
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline),
                                onPressed: () => _deleteEmail(index),
                                tooltip: 'Delete',
                              ),
                              IconButton(
                                icon: Icon(Icons.mail_outline),
                                onPressed: () => _markAsRead(index),
                                tooltip: 'Mark as read',
                              ),
                              IconButton(
                                icon: Icon(Icons.schedule_outlined),
                                onPressed: () => _snoozeEmail(index),
                                tooltip: 'Snooze',
                              ),
                            ],
                          ),
                        // Star Icon button
                        IconButton(
                          icon: Icon(
                            email['isStarred'] == true ? Icons.star : Icons.star_border,
                            color: email['isStarred'] == true ? Colors.amber : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey[600]),
                          ),
                          onPressed: () {
                            // Use the index from the filtered list to toggle star status
                            _toggleStar(index);
                          },
                        ),
                      ],
                    ),
                    // Original onTap for email details
                    onTap: () => _openEmailDetails(email),
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

  // Pass index to detailed item builder
  Widget _buildDetailedEmailItem(Map<String, dynamic> email, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: email['isStarred'] == true ? Colors.amber : Colors.grey,
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
            if (email['hasAttachment'] == true)
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

  // Pass index to basic item builder
  Widget _buildBasicEmailItem(Map<String, dynamic> email, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: email['isStarred'] == true ? Colors.amber : Colors.grey,
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
            // Reset checked state when category changes
            // Ensure the emails list is treated as List<Map<String, dynamic>>
            final currentEmails = _emailCategories[_selectedIndex]['emails'];
             if (currentEmails is List) {
               _checkedEmails = List<bool>.filled(currentEmails.length, false);
             } else {
               _checkedEmails = [];
             }
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Calculate email count for the current filter chip label within the Inbox category
    int emailCount = 0;
    final inboxEmails = _emailCategories.firstWhere((category) => category['name'] == 'Inbox')['emails'];
    if (inboxEmails is List<Map<String, dynamic>>) {
      if (label == 'Primary') {
        // Primary shows all emails in Inbox
        emailCount = inboxEmails.length;
      } else {
        // Count emails matching the specific category label
        emailCount = inboxEmails.where((email) => email['category'] == label).length;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (themeProvider.isDarkMode ? Colors.black87 : Colors.white)
                  : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey[700]),
            ),
            const SizedBox(width: 8),
            Text(
              '$label${emailCount > 0 ? ' ($emailCount)' : ''}',
            ),
          ],
        ),
        selected: _selectedFilterChipLabel == label,
        selectedColor: themeProvider.isDarkMode ? Colors.blueGrey[700] : Colors.purple[100],
        labelStyle: TextStyle(
           color: isSelected
                  ? (themeProvider.isDarkMode ? Colors.white : Colors.black87)
                  : (themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[700]),
        ),
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedFilterChipLabel = label;
              _checkedEmails = List<bool>.filled(_filteredEmails.length, false);
              _hoveredEmailIndex = null;
            });
          }
        },
      ),
    );
  }
} 