import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  static AppConfig get current => AppConfig(
        apiBaseUrl: baseUrlFrom(
          define: const String.fromEnvironment('API_BASE_URL'),
          hostIsAndroid: !kIsWeb && Platform.isAndroid,
        ),
      );

  static String baseUrlFrom({
    required String define,
    bool hostIsAndroid = false,
  }) {
    if (define.isNotEmpty) return define;
    return hostIsAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  }

  String get wsBaseUrl => apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');
}
