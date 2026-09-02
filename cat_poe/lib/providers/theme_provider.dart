import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'theme_preference';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemePreference();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final prefString = prefs.getString(_themePrefKey);

    if (prefString != null) {
      if (prefString == 'light') {
        _themeMode = ThemeMode.light;
      } else if (prefString == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    String saveKey = 'system';
    if (mode == ThemeMode.light) saveKey = 'light';
    if (mode == ThemeMode.dark) saveKey = 'dark';

    await prefs.setString(_themePrefKey, saveKey);
  }
}


