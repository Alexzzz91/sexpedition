// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<String?> readStoredLocale(String key) async {
  return html.window.localStorage[key];
}

Future<void> writeStoredLocale(String key, String? value) async {
  if (value == null) {
    html.window.localStorage.remove(key);
  } else {
    html.window.localStorage[key] = value;
  }
}

