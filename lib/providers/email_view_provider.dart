import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailViewProvider with ChangeNotifier {
  bool _isDetailedView = false;
  bool get isDetailedView => _isDetailedView;

  EmailViewProvider() {
    _loadViewPreference();
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDetailedView = prefs.getBool('isDetailedView') ?? false;
    notifyListeners();
  }

  Future<void> toggleViewMode() async {
    _isDetailedView = !_isDetailedView;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDetailedView', _isDetailedView);
    notifyListeners();
  }
} 