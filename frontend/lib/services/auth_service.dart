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
  final String _baseUrl = kIsWeb
      ? 'http://localhost:3000/api/auth'
      : 'http://192.168.2.62:3000/api/auth';

  String? get token => _token;
  User? get user => _user;

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt');
    if (_token != null) {
      final valid = await verifyToken();
      if (!valid) {
        await prefs.remove('jwt');
        _token = null;
      }
    }
    return _token != null;
  }

  Future<bool> register(String phone, String password, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
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
        Uri.parse('$_baseUrl/login'),
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
          return false;
        }
        _token = data['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', _token!);
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
      
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/update-profile'));
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

      final response = await request.send().timeout(Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (_user == null) {
          _user = User(phone: '', email: email, name: name);
        } else {
          _user = User(phone: _user!.phone, email: email, name: name);
        }
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
        Uri.parse('$_baseUrl/forgot-password'),
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
        Uri.parse('$_baseUrl/reset-password'),
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

  Future<bool> changePassword(String phone, String oldPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      if (response.statusCode == 200) return true;
      throw jsonDecode(response.body)['error'] ?? 'Change password failed';
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
        Uri.parse('$_baseUrl/verify-token'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
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