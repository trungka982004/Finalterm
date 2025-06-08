import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'dart:io';
import '../main.dart'; // Import main.dart for ThemeProvider

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isSaving = false;
  bool _isEmailLocked = true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user != null) {
      _nameController.text = authService.user!.name ?? '';
      _emailController.text = authService.user!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final success = await authService.updateProfile(
        _emailController.text,
        _nameController.text,
        _imageFile,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _imageFile = null;
          _isEmailLocked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggle2FA(bool value) async {
    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.toggle2FA();
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Two-Factor Authentication ${value ? "Enabled" : "Disabled"}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showUnlockConfirmationDialog() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Email Change'),
        content: const Text(
          'Changing your email may result in losing access to some emails. Are you sure you want to change it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isEmailLocked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Consumer2<AuthService, ThemeProvider>(
        builder: (context, authService, themeProvider, child) {
          if (authService.user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(authService),
                const SizedBox(height: 32),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          readOnly: _isEmailLocked,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_isEmailLocked ? Icons.lock : Icons.lock_open),
                              onPressed: () {
                                if (_isEmailLocked) {
                                  _showUnlockConfirmationDialog();
                                } else {
                                  setState(() {
                                    _isEmailLocked = true;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Two-Factor Authentication', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(authService.user!.isEmailVerified ? 'Recommended for extra security' : 'Requires a verified email'),
                          value: authService.user!.twoFactorEnabled,
                          onChanged: authService.user!.isEmailVerified && !_isSaving ? _toggle2FA : null,
                          secondary: const Icon(Icons.security_outlined),
                          activeColor: Colors.green,
                        ),
                        SwitchListTile(
                          title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: const Text('Toggle between light and dark themes'),
                          value: themeProvider.isDarkMode,
                          onChanged: _isSaving
                              ? null
                              : (value) async {
                                  await themeProvider.toggleTheme();
                                },
                          secondary: const Icon(Icons.dark_mode_outlined),
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _updateProfile,
                  icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save_alt_outlined),
                  label: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AuthService authService) {
    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(File(_imageFile!.path))
                    : (authService.user?.picture != null && authService.user!.picture!.isNotEmpty
                        ? NetworkImage(authService.user!.picture!)
                        : null) as ImageProvider?,
                child: _imageFile == null && (authService.user?.picture == null || authService.user!.picture!.isEmpty)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                  child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onSurface, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          authService.user!.name ?? 'Username',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          authService.user!.email ?? 'user.email@example.com',
          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}