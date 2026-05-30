// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:js_util' as js_util;

import 'package:flutter/foundation.dart';

class TelegramWebAppState {
  const TelegramWebAppState({
    required this.isAvailable,
    required this.isExpanded,
    required this.colorScheme,
    required this.themeParams,
    required this.initData,
    required this.initDataUnsafe,
  });

  final bool isAvailable;
  final bool isExpanded;
  final String? colorScheme;
  final Map<String, dynamic> themeParams;
  final String initData;
  final Map<String, dynamic>? initDataUnsafe;

  bool get hasInitData => initData.trim().isNotEmpty;

  static const empty = TelegramWebAppState(
    isAvailable: false,
    isExpanded: false,
    colorScheme: null,
    themeParams: {},
    initData: '',
    initDataUnsafe: null,
  );
}

class TelegramWebAppService {
  TelegramWebAppService._();

  static final TelegramWebAppService instance = TelegramWebAppService._();

  TelegramWebAppState get state {
    if (!kIsWeb) return TelegramWebAppState.empty;
    try {
      final bridge = js_util.getProperty<Object?>(
        js_util.globalThis,
        'sexpTelegramWebAppBridge',
      );
      if (bridge == null) return TelegramWebAppState.empty;
      final raw = js_util.callMethod<String>(bridge, 'getState', []);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return TelegramWebAppState(
        isAvailable: decoded['isAvailable'] == true,
        isExpanded: decoded['isExpanded'] == true,
        colorScheme: decoded['colorScheme'] as String?,
        themeParams:
            (decoded['themeParams'] as Map?)?.cast<String, dynamic>() ?? {},
        initData: decoded['initData'] as String? ?? '',
        initDataUnsafe:
            (decoded['initDataUnsafe'] as Map?)?.cast<String, dynamic>(),
      );
    } catch (_) {
      return TelegramWebAppState.empty;
    }
  }

  bool get isInTelegramWebApp => state.isAvailable;

  String get initData => state.initData;

  void close() {
    if (!kIsWeb) return;
    try {
      final bridge = js_util.getProperty<Object?>(
        js_util.globalThis,
        'sexpTelegramWebAppBridge',
      );
      if (bridge == null) return;
      js_util.callMethod<void>(bridge, 'close', []);
    } catch (_) {}
  }
}
