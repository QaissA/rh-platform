import 'package:alize_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses dart-define override', () {
    expect(
      AppConfig.baseUrlFrom(define: 'https://api.example.com'),
      'https://api.example.com',
    );
  });

  test('android emulator default is 10.0.2.2', () {
    expect(
      AppConfig.baseUrlFrom(define: '', hostIsAndroid: true),
      'http://10.0.2.2:3000',
    );
  });

  test('elsewhere default is localhost', () {
    expect(
      AppConfig.baseUrlFrom(define: '', hostIsAndroid: false),
      'http://localhost:3000',
    );
  });

  test('wsBaseUrl replaces http with ws', () {
    const config = AppConfig(apiBaseUrl: 'http://localhost:3000');
    expect(config.wsBaseUrl, 'ws://localhost:3000');
  });

  test('wsBaseUrl replaces https with wss', () {
    const config = AppConfig(apiBaseUrl: 'https://api.example.com');
    expect(config.wsBaseUrl, 'wss://api.example.com');
  });
}
