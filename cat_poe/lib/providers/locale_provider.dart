import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _localePrefKey = 'app_locale';

  Locale _locale = const Locale('en');

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('vi'),
    Locale('zh'),
    Locale('es'),
    Locale('hi'),
    Locale('te'),
    Locale('ta'),
    Locale('ru'),
    Locale('ja'),
    Locale('ms'),
    Locale('id'),
    Locale('ko'),
    Locale('ar'),
    Locale('fr'),
    Locale('gu'),
    Locale('or'),
  ];

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localePrefKey, locale.languageCode);
  }
}

