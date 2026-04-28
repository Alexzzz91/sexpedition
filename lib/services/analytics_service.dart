import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: _sanitizeParameters(parameters),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Analytics event failed: $name | error: $error\n$stackTrace',
      );
    }
  }

  Map<String, Object> _sanitizeParameters(Map<String, Object?> parameters) {
    final result = <String, Object>{};
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is String || value is num || value is bool) {
        result[key] = value;
      } else {
        result[key] = value.toString();
      }
    });
    return result;
  }
}
