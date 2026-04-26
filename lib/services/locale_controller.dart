import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const List<Locale> supportedAppLocales = [
  Locale('ru'),
  Locale('en'),
  Locale('th'),
  Locale('de'),
  Locale('fr'),
  Locale('sv'),
  Locale('zh'),
  Locale('kk'),
  Locale('uz'),
  Locale('hy'),
];

const Map<String, String> supportedAppLanguageNames = {
  'ru': 'Русский',
  'en': 'English',
  'th': 'ไทย',
  'de': 'Deutsch',
  'fr': 'Français',
  'sv': 'Svenska',
  'zh': '中文',
  'kk': 'Қазақша',
  'uz': 'O‘zbekcha',
  'hy': 'Հայերեն',
};

class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const String _prefKey = 'selected_locale';

  Locale? _locale;

  Locale? get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_prefKey);
    if (languageCode == null || languageCode.isEmpty) return;
    _locale = Locale(languageCode);
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, locale.languageCode);
    }
    notifyListeners();
  }
}
