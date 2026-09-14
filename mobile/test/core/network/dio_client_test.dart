import 'dart:typed_data';

import 'package:alize_mobile/core/config/app_config.dart';
import 'package:alize_mobile/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode);

  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthInterceptor', () {
    test('adds Bearer Authorization when token is present', () {
      final interceptor = AuthInterceptor(
        token: () => 'abc123',
        onUnauthorized: () {},
      );
      final options = RequestOptions(path: '/me');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['Authorization'], 'Bearer abc123');
    });

    test('does not set Authorization when token is empty', () {
      final interceptor = AuthInterceptor(
        token: () => '',
        onUnauthorized: () {},
      );
      final options = RequestOptions(path: '/me');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('does not set Authorization when token is null', () {
      final interceptor = AuthInterceptor(
        token: () => null,
        onUnauthorized: () {},
      );
      final options = RequestOptions(path: '/me');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('invokes onUnauthorized on 401', () async {
      var called = false;
      final interceptor = AuthInterceptor(
        token: () => 'abc123',
        onUnauthorized: () => called = true,
      );
      final dio = Dio()
        ..interceptors.add(interceptor)
        ..httpClientAdapter = _StatusAdapter(401);

      await expectLater(dio.get<void>('/me'), throwsA(isA<DioException>()));
      expect(called, isTrue);
    });

    test('does not invoke onUnauthorized on non-401', () async {
      var called = false;
      final interceptor = AuthInterceptor(
        token: () => 'abc123',
        onUnauthorized: () => called = true,
      );
      final dio = Dio()
        ..interceptors.add(interceptor)
        ..httpClientAdapter = _StatusAdapter(500);

      await expectLater(dio.get<void>('/me'), throwsA(isA<DioException>()));
      expect(called, isFalse);
    });
  });

  group('createDio', () {
    test(
      'uses AppConfig baseUrl, timeouts, Accept header, and interceptor',
      () {
        final interceptor = AuthInterceptor(
          token: () => null,
          onUnauthorized: () {},
        );
        final dio = createDio(
          config: const AppConfig(apiBaseUrl: 'http://example.test'),
          interceptor: interceptor,
        );

        expect(dio.options.baseUrl, 'http://example.test');
        expect(dio.options.connectTimeout, const Duration(seconds: 15));
        expect(dio.options.receiveTimeout, const Duration(seconds: 20));
        expect(dio.options.headers['Accept'], 'application/json');
        expect(dio.interceptors, contains(interceptor));
      },
    );
  });
}
