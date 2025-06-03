import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auto_answer_provider.dart';
import '../widgets/auto_answer_dialog.dart';
import '../widgets/edit_profile_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _autoAnswerEnabled = false;
  bool _twoStepVerificationEnabled = false;
  String _name = 'User Name';
  String _email = 'user@example.com';
  String _phoneNumber = '+1 234 567 8900';
  
  // Email editor preferences
  double _fontSize = 16.0;
  String _selectedFontFamily = 'Roboto';
  final List<String> _fontFamilies = [
    'Roboto',
    'Arial',
    'Times New Roman',
    'Helvetica',
    'Georgia',
    'Courier New',
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
        titleTextStyle: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: ListView(
        children: [
          // Profile Management Section (like Profile page header)
          Container(
            padding: const EdgeInsets.all(24),
            color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showEditProfileDialog(),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: Image.asset(
                          'assets/images/avatar-default.png',
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: themeProvider.isDarkMode ? Colors.grey[900]! : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _phoneNumber,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // General Settings Card
          Card(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Padding(
                   padding: const EdgeInsets.all(16),
                   child: Text(
                      'GENERAL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.blue,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    title: Text(
                      'Notifications',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    secondary: Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: _notificationsEnabled
                          ? Colors.blue
                          : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey),
                    ),
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.brightness_6_outlined,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (bool value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),
              ]
            )
          ),

          // Account Management Card
          Card(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Padding(
                   padding: const EdgeInsets.all(16),
                   child: Text(
                      'Account Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.blue,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.lock,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.security,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    title: Text(
                      'Password Recovery',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showPasswordRecoveryDialog(),
                  ),
                  SwitchListTile(
                    title: Text(
                      'Two-Step Verification',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Add an extra layer of security',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    secondary: Icon(
                      _twoStepVerificationEnabled
                          ? Icons.verified_user
                          : Icons.verified_user_outlined,
                      color: _twoStepVerificationEnabled
                          ? Colors.green
                          : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey),
                    ),
                    value: _twoStepVerificationEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _twoStepVerificationEnabled = value;
                      });
                      if (value) {
                        _showTwoStepVerificationSetupDialog();
                      }
                    },
                  ),
              ]
            )
          ),

          // Email Editor Preferences Card
          Card(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Padding(
                   padding: const EdgeInsets.all(16),
                   child: Text(
                      'Email Editor Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.blue,
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Font Size',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${_fontSize.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    leading: Icon(
                      Icons.format_size,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove,
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                          onPressed: () {
                            if (_fontSize > 12) {
                              setState(() => _fontSize -= 1);
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                          ),
                          onPressed: () {
                            if (_fontSize < 24) {
                              setState(() => _fontSize += 1);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: Text(
                      'Font Family',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      _selectedFontFamily,
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    leading: Icon(
                      Icons.font_download,
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    trailing: DropdownButton<String>(
                      value: _selectedFontFamily,
                      items: _fontFamilies.map((String font) {
                        return DropdownMenuItem<String>(
                          value: font,
                          child: Text(
                            font,
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFontFamily = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  SwitchListTile(
                    title: Text(
                      'Auto Answer Mode',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Automatically generate email responses',
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    secondary: Icon(
                      _autoAnswerEnabled ? Icons.auto_awesome : Icons.auto_awesome_motion,
                      color: _autoAnswerEnabled
                          ? Colors.green
                          : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey),
                    ),
                    value: _autoAnswerEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _autoAnswerEnabled = value;
                      });
                      final autoAnswerProvider = Provider.of<AutoAnswerProvider>(context, listen: false);
                      autoAnswerProvider.toggleAutoAnswer(value);
                    },
                  ),
                  if (_autoAnswerEnabled)
                    ListTile(
                      leading: Icon(
                        Icons.edit,
                        color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                      title: Text(
                        'Customize Auto-Reply Message',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => const AutoAnswerDialog(),
                        );
                      },
                    ),
              ]
            )
          ),

          // Sign Out Card
          Card(
             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.red[400],
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.red[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                // TODO: Implement sign out logic
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    // TODO: Implement change password dialog
  }

  void _showPasswordRecoveryDialog() {
    // TODO: Implement password recovery dialog
  }

  void _showTwoStepVerificationSetupDialog() {
    // TODO: Implement two-step verification setup dialog
  }

  void _showEditProfileDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditProfileDialog(
        currentName: _name,
        currentEmail: _email,
        currentPhone: _phoneNumber,
      ),
    );

    if (result != null) {
      setState(() {
        _name = result['name'] as String;
        _email = result['email'] as String;
        _phoneNumber = result['phone'] as String;
        // TODO: Handle avatar change if needed
      });
    }
  }
} 