import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();
  bool _showOtpAndPasswordFields = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneFocusNode.dispose();
    _otpFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final success = await authService.forgotPassword(_phoneController.text);
      if (success) {
        setState(() => _showOtpAndPasswordFields = true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error ?? 'An error occurred'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final success = await authService.resetPassword(
        _phoneController.text,
        _otpController.text,
        _newPasswordController.text,
        _confirmPasswordController.text,
      );
      if (success) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_error ?? 'An error occurred'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: Colors.blueAccent,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade200, Colors.white],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 600;
                final maxWidth = isLargeScreen ? 500.0 : constraints.maxWidth * 0.9;
                final padding = isLargeScreen ? 48.0 : 24.0;
                final logoSize = isLargeScreen ? 120.0 : 80.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Form(
                          key: _formKey,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: isLargeScreen ? 80 : 40),
                                Card(
                                  elevation: 10,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      children: [
                                        ScaleTransition(
                                          scale: _scaleAnimation,
                                          child: Image.network(
                                            'https://www.gstatic.com/images/branding/product/1x/gmail_48dp.png',
                                            height: logoSize,
                                            errorBuilder: (context, error, stackTrace) => Icon(
                                              Icons.email,
                                              size: logoSize,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Reset Password Gmail Clone',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        TextFormField(
                                          controller: _phoneController,
                                          focusNode: _phoneFocusNode,
                                          keyboardType: TextInputType.phone,
                                          decoration: const InputDecoration(
                                            labelText: 'Phone Number',
                                            prefixIcon: Icon(Icons.phone),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your phone number';
                                            }
                                            if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                                              return 'Please enter a valid phone number';
                                            }
                                            return null;
                                          },
                                          onFieldSubmitted: (_) {
                                            if (!_showOtpAndPasswordFields) {
                                              _sendOtp();
                                            } else {
                                              _otpFocusNode.requestFocus();
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        if (_showOtpAndPasswordFields)
                                          TextFormField(
                                            controller: _otpController,
                                            focusNode: _otpFocusNode,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'OTP',
                                              prefixIcon: Icon(Icons.security),
                                            ),
                                            validator: (value) {
                                              if (_showOtpAndPasswordFields && (value == null || value.isEmpty)) {
                                                return 'Please enter the OTP';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) {
                                              _newPasswordFocusNode.requestFocus();
                                            },
                                          ),
                                        if (_showOtpAndPasswordFields) const SizedBox(height: 16),
                                        if (_showOtpAndPasswordFields)
                                          TextFormField(
                                            controller: _newPasswordController,
                                            focusNode: _newPasswordFocusNode,
                                            obscureText: !_isNewPasswordVisible,
                                            decoration: InputDecoration(
                                              labelText: 'New Password',
                                              prefixIcon: const Icon(Icons.lock),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                                  color: Colors.blueAccent,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _isNewPasswordVisible = !_isNewPasswordVisible;
                                                  });
                                                },
                                              ),
                                            ),
                                            validator: (value) {
                                              if (_showOtpAndPasswordFields && (value == null || value.isEmpty)) {
                                                return 'Please enter your new password';
                                              }
                                              if (_showOtpAndPasswordFields && value!.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) {
                                              _confirmPasswordFocusNode.requestFocus();
                                            },
                                          ),
                                        if (_showOtpAndPasswordFields) const SizedBox(height: 16),
                                        if (_showOtpAndPasswordFields)
                                          TextFormField(
                                            controller: _confirmPasswordController,
                                            focusNode: _confirmPasswordFocusNode,
                                            obscureText: !_isConfirmPasswordVisible,
                                            decoration: InputDecoration(
                                              labelText: 'Confirm Password',
                                              prefixIcon: const Icon(Icons.lock_outline),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                                  color: Colors.blueAccent,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                                  });
                                                },
                                              ),
                                            ),
                                            validator: (value) {
                                              if (_showOtpAndPasswordFields && (value == null || value.isEmpty)) {
                                                return 'Please confirm your password';
                                              }
                                              if (_showOtpAndPasswordFields && value != _newPasswordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                            onFieldSubmitted: (_) => _resetPassword(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : (_showOtpAndPasswordFields ? _resetPassword : _sendOtp),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _showOtpAndPasswordFields ? 'Reset Password' : 'Send OTP',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Back to login?"),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/login');
                                      },
                                      child: const Text(
                                        'Login',
                                        style: TextStyle(color: Colors.blueAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}