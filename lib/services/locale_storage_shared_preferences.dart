import 'package:shared_preferences/shared_preferences.dart';

Future<String?> readStoredLocale(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> writeStoredLocale(String key, String? value) async {
  final prefs = await SharedPreferences.getInstance();
  if (value == null) {
    await prefs.remove(key);
  } else {
    await prefs.setString(key, value);
  }
}

