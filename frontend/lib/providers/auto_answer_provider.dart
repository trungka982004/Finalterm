import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoAnswerProvider with ChangeNotifier {
  bool _isEnabled = false;
  String _defaultMessage = 'Thank you for your email. I am currently using auto-reply mode. I will get back to you as soon as possible.';
  final SharedPreferences? _prefs;

  AutoAnswerProvider(this._prefs) {
    _loadSettings();
  }

  bool get isEnabled => _isEnabled;
  String get defaultMessage => _defaultMessage;

  void _loadSettings() {
    if (_prefs != null) {
      _isEnabled = _prefs!.getBool('auto_answer_enabled') ?? false;
      _defaultMessage = _prefs!.getString('auto_answer_message') ?? _defaultMessage;
    }
    notifyListeners();
  }

  Future<void> toggleAutoAnswer(bool value) async {
    _isEnabled = value;
    if (_prefs != null) {
      await _prefs!.setBool('auto_answer_enabled', value);
    }
    notifyListeners();
  }

  Future<void> updateMessage(String message) async {
    _defaultMessage = message;
    if (_prefs != null) {
      await _prefs!.setString('auto_answer_message', message);
    }
    notifyListeners();
  }

  String generateResponse(String senderName, String subject) {
    return _defaultMessage.replaceAll('{sender}', senderName)
        .replaceAll('{subject}', subject);
  }
} 