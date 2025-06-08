import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:email_validator/email_validator.dart';
import 'dart:io' show File;
import '../services/auth_service.dart';
import '../main.dart'; // Import for ThemeProvider

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  XFile? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final fileSize = await pickedFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image size exceeds 5MB limit')),
        );
        return;
      }
      final mimeType = pickedFile.mimeType ?? _getMimeType(pickedFile.name);
      if (!['image/jpeg', 'image/jpg', 'image/png'].contains(mimeType)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only .jpg, .jpeg, .png files are allowed')),
        );
        return;
      }
      setState(() => _image = pickedFile);
    }
  }

  String _getMimeType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _updateProfile() async {
    if (!EmailValidator.validate(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    final authService = Provider.of<AuthService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final success = await authService.updateProfile(
        _emailController.text,
        _nameController.text.isEmpty ? null : _nameController.text,
        _image,
      );
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      final errorMessage = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      if (errorMessage.contains('Session expired')) {
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, '/login');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Setup Your Profile',
              style: TextStyle(
                fontSize: isLargeScreen ? 24 : 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = isLargeScreen ? 600.0 : size.width;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 32.0 : 24.0,
                      vertical: isLargeScreen ? 40.0 : 32.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: isLargeScreen ? size.width * 0.1 : 60,
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                            child: _image == null
                                ? Icon(
                                    Icons.person,
                                    size: isLargeScreen ? size.width * 0.1 : 60,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  )
                                : ClipOval(
                                    child: kIsWeb
                                        ? FutureBuilder<Uint8List>(
                                            future: _image!.readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Image.memory(
                                                  snapshot.data!,
                                                  fit: BoxFit.cover,
                                                  width: isLargeScreen ? size.width * 0.2 : 120,
                                                  height: isLargeScreen ? size.width * 0.2 : 120,
                                                );
                                              }
                                              return const CircularProgressIndicator();
                                            },
                                          )
                                        : Image.file(
                                            File(_image!.path),
                                            fit: BoxFit.cover,
                                            width: isLargeScreen ? size.width * 0.2 : 120,
                                            height: isLargeScreen ? size.width * 0.2 : 120,
                                          ),
                                  ),
                          ),
                        ),
                        SizedBox(height: isLargeScreen ? 24 : 16),
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: Icon(
                            Icons.camera_alt,
                            size: isLargeScreen ? 28 : 24,
                          ),
                          label: Text(
                            'Change Profile Picture',
                            style: TextStyle(fontSize: isLargeScreen ? 18 : 16),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: isLargeScreen ? 40 : 32),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email (Required)',
                            prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant,
                            labelStyle: TextStyle(fontSize: isLargeScreen ? 18 : 16),
                          ),
                        ),
                        SizedBox(height: isLargeScreen ? 24 : 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Name (Optional)',
                            prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceVariant,
                            labelStyle: TextStyle(fontSize: isLargeScreen ? 18 : 16),
                          ),
                        ),
                        SizedBox(height: isLargeScreen ? 40 : 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: isLargeScreen ? 20 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              shadowColor: Theme.of(context).colorScheme.shadow,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: isLargeScreen ? 28 : 24,
                                    height: isLargeScreen ? 28 : 24,
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save Profile',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}