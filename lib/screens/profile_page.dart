import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auto_answer_provider.dart';
import '../widgets/auto_answer_dialog.dart';
import '../widgets/edit_profile_dialog.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
        title: const Text('Profile'),
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
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
            const Divider(height: 1),
            // Quick Actions
            ListTile(
              leading: Icon(
                Icons.help_outline,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
              ),
              title: Text(
                'Help & Support',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showHelpAndSupportDialog();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
              ),
              title: Text(
                'About',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showAboutDialog();
              },
            ),
            // Account Management Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'Account Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.blue,
                  ),
                ),
              ),
            ),
            // Change Password
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
            // Password Recovery
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
            // Two-Step Verification
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
            const Divider(),
            // Theme Switch
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Toggle dark/light theme',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: themeProvider.isDarkMode ? Colors.amber : Colors.grey,
              ),
              value: themeProvider.isDarkMode,
              onChanged: (bool value) {
                themeProvider.toggleTheme();
              },
            ),
            // Notifications Switch
            SwitchListTile(
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Enable/disable notifications',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              secondary: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
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
            const Divider(),
            // Email Editor Preferences Section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                'Email Editor Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.blue,
                ),
              ),
            ),
            // Font Size Slider
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
            // Font Family Dropdown
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
            // Auto Answer Switch
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
            // Customize Auto-Answer Message Button
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
            const Divider(),
            // Sign Out Button
            ListTile(
              leading: Icon(
                Icons.logout,
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                // TODO: Implement sign out logic
                Navigator.pop(context);
              },
            ),
          ],
        ),
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

  void _showHelpAndSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help? Here are some ways to get support:'),
            const SizedBox(height: 16),
            _buildSupportItem(Icons.email, 'Email Support', 'support@example.com'),
            const SizedBox(height: 8),
            _buildSupportItem(Icons.chat, 'Live Chat', 'Available 24/7'),
            const SizedBox(height: 8),
            _buildSupportItem(Icons.phone, 'Phone Support', '+1 (555) 123-4567'),
            const SizedBox(height: 8),
            _buildSupportItem(Icons.help_outline, 'FAQs', 'Visit our FAQ section'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Gmail App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gmail App v1.0.0'),
            const SizedBox(height: 8),
            const Text('A modern email client built with Flutter'),
            const SizedBox(height: 16),
            const Text('Features:'),
            _buildFeatureItem('• Dark/Light mode support'),
            _buildFeatureItem('• Advanced email search'),
            _buildFeatureItem('• Auto-answer functionality'),
            _buildFeatureItem('• Customizable email editor'),
            _buildFeatureItem('• Secure authentication'),
            const SizedBox(height: 16),
            const Text('© 2024 Gmail App. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text),
    );
  }
} 