import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  String? _token;
  User? _user;
  bool _isFetchingProfile = false; // Prevent multiple simultaneous getProfile calls
  final String _baseUrlAuth = kIsWeb
      ? 'https://gmail-backend-1-wlx4.onrender.com/api/auth'
      : 'http://192.168.2.62:3000/api/auth'; // Consistent IP
  final String _baseUrlUser = kIsWeb
      ? 'https://gmail-backend-1-wlx4.onrender.com/api/user'
      : 'http://192.168.2.62:3000/api/user'; // Consistent IP

  String? get token => _token;
  User? get user => _user;
  bool get isAuthenticated => _token != null && _user != null;

  Future<bool> tryAutoLogin() async {
    if (_user != null) {
      return true; // Skip if user is already loaded
    }
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('jwt');
    if (storedToken == null) {
      return false;
    }
    _token = storedToken;

    try {
      await getProfile();
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  Future<void> getProfile() async {
    if (_isFetchingProfile || _token == null) return;
    _isFetchingProfile = true;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrlUser/profile'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (response.statusCode == 200) {
        _user = User.fromJson(jsonDecode(response.body));
        notifyListeners();
      } else {
        throw 'Failed to load profile. Status: ${response.statusCode}, Body: ${response.body}';
      }
    } catch (e) {
      throw 'Failed to load profile: $e';
    } finally {
      _isFetchingProfile = false;
    }
  }

  Future<bool> register(String phone, String password, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrlAuth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', _token!);
        await getProfile(); // Load profile after registration
        notifyListeners();
        return true;
      }
      throw jsonDecode(response.body)['error'] ?? 'Registration failed';
    } catch (e) {
      throw 'Error: $e';
    }
  }

  Future<bool> login(String phone, String password, {String? otp}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrlAuth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          if (otp != null) 'otp': otp,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['message'] == 'OTP sent to your email') {
          return false; // OTP required
        }
        _token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', _token!);
        await getProfile(); // Load profile after login
        notifyListeners();
        return true;
      }
      throw jsonDecode(response.body)['error'] ?? 'Login failed';
    } catch (e) {
      throw 'Error: $e';
    }
  }

  Future<bool> updateProfile(String email, String? name, XFile? image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null) throw 'No token found. Please log in again.';

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrlUser/update-profile'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['email'] = email;
      if (name != null) request.fields['name'] = name;

      if (image != null) {
        final fileSize = await image.length();
        if (fileSize == 0) throw 'Image file is empty or invalid';

        final mimeType = image.mimeType ?? _getMimeType(image.name);
        if (!['image/jpeg', 'image/jpg', 'image/png'].contains(mimeType)) {
          throw 'Only .jpg, .jpeg, .png files are allowed';
        }

        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'picture',
            bytes,
            filename: image.name.isEmpty ? 'profile.png' : _ensureValidExtension(image.name),
            contentType: MediaType.parse(mimeType),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'picture',
            image.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_user == null) {
          _user = User(phone: '', email: email, name: name);
        } else {
          _user = User(
            phone: _user!.phone,
            email: email,
            name: name,
            picture: _user!.picture, // Preserve existing picture if no new image
            twoFactorEnabled: _user!.twoFactorEnabled,
            isEmailVerified: _user!.isEmailVerified,
          );
        }
        await getProfile(); // Refresh profile from server
        notifyListeners();
        return true;
      }
      if (response.statusCode == 401) {
        await logout();
        throw 'Session expired. Please log in again.';
      }
      try {
        throw jsonDecode(responseBody)['error'] ?? 'Update failed';
      } catch (e) {
        throw 'Invalid response format: $responseBody';
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw 'Network error: Could not connect to the server. Check if the backend is running.';
      }
      if (e is TimeoutException) {
        throw 'Request timed out. Please check your network connection.';
      }
      throw 'Error: $e';
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

  String _ensureValidExtension(String filename) {
    if (filename.toLowerCase().endsWith('.jpg') ||
        filename.toLowerCase().endsWith('.jpeg') ||
        filename.toLowerCase().endsWith('.png')) {
      return filename;
    }
    return '$filename.png';
  }

  Future<bool> forgotPassword(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrlAuth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      if (response.statusCode == 200) return true;
      throw jsonDecode(response.body)['error'] ?? 'Failed to send OTP';
    } catch (e) {
      throw 'Error: $e';
    }
  }

  Future<bool> resetPassword(String phone, String otp, String newPassword, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrlAuth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      if (response.statusCode == 200) return true;
      throw jsonDecode(response.body)['error'] ?? 'Reset failed';
    } catch (e) {
      throw 'Error: $e';
    }
  }

// auth_service.dart
// lib/services/auth_service.dart

// Đảm bảo hàm này chỉ có 3 tham số: oldPassword, newPassword, confirmPassword
Future<bool> changePassword(String oldPassword, String newPassword, String confirmPassword) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt');
  if (token == null) {
    throw 'Authentication token not found. Please log in again.';
  }

  try {
    final response = await http.post(
      Uri.parse('$_baseUrlUser/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode == 200) return true;

    final errorBody = jsonDecode(response.body);
    throw errorBody['error'] ?? 'Change password failed';
  } catch (e) {
    throw 'Error: $e';
  }
}

  Future<bool> verifyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null) return false;
      final response = await http.get(
        Uri.parse('$_baseUrlAuth/verify-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggle2FA() async {
  if (_token == null) throw 'Not authenticated';

  try {
    final response = await http.post(
      Uri.parse('$_baseUrlUser/toggle-2fa'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newStatus = data['twoFactorEnabled'] as bool;

      // Cập nhật trạng thái 2FA của user local
      if (_user != null) {
        _user = User(
          phone: _user!.phone,
          email: _user!.email,
          name: _user!.name,
          picture: _user!.picture,
          twoFactorEnabled: newStatus, // Cập nhật giá trị mới
          isEmailVerified: _user!.isEmailVerified,
        );
        notifyListeners(); // Thông báo cho UI cập nhật
      }
      return newStatus;
    } else {
      final errorBody = jsonDecode(response.body);
      throw errorBody['error'] ?? 'Failed to toggle 2FA';
    }
  } catch (e) {
    throw 'Error: $e';
  }
}

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    _token = null;
    _user = null;
    notifyListeners();
  }
}