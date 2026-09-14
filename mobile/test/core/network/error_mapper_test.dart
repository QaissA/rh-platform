import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DioException dio({
    DioExceptionType type = DioExceptionType.badResponse,
    int? status,
    dynamic data,
    String? statusMessage,
  }) {
    final options = RequestOptions(path: '/');
    return DioException(
      requestOptions: options,
      type: type,
      response: status == null
          ? null
          : Response<dynamic>(
              requestOptions: options,
              statusCode: status,
              data: data,
              statusMessage: statusMessage,
            ),
    );
  }

  test('connectionError maps to NetworkFailure', () {
    expect(
      mapDio(dio(type: DioExceptionType.connectionError)),
      isA<NetworkFailure>(),
    );
  });

  test('connectionTimeout maps to NetworkFailure', () {
    expect(
      mapDio(dio(type: DioExceptionType.connectionTimeout)),
      isA<NetworkFailure>(),
    );
  });

  test('sendTimeout maps to NetworkFailure', () {
    expect(
      mapDio(dio(type: DioExceptionType.sendTimeout)),
      isA<NetworkFailure>(),
    );
  });

  test('receiveTimeout maps to NetworkFailure', () {
    expect(
      mapDio(dio(type: DioExceptionType.receiveTimeout)),
      isA<NetworkFailure>(),
    );
  });

  test('unknown without response maps to NetworkFailure', () {
    expect(
      mapDio(dio(type: DioExceptionType.unknown)),
      isA<NetworkFailure>(),
    );
  });

  test('401 maps to UnauthorizedFailure', () {
    expect(mapDio(dio(status: 401)), isA<UnauthorizedFailure>());
  });

  test('404 maps to NotFoundFailure', () {
    expect(mapDio(dio(status: 404)), isA<NotFoundFailure>());
  });

  test('422 uses error string from JSON body', () {
    final failure = mapDio(dio(status: 422, data: {'error': 'Email invalide'}));
    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).message, 'Email invalide');
  });

  test('422 joins errors list from JSON body', () {
    final failure = mapDio(
      dio(status: 422, data: {'errors': ['Nom requis', 'Email invalide']}),
    );
    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).message, 'Nom requis, Email invalide');
  });

  test('other 4xx maps to ServerFailure with status and message', () {
    final failure = mapDio(
      dio(status: 403, data: {'error': 'Accès refusé'}),
    );
    expect(failure, isA<ServerFailure>());
    final server = failure as ServerFailure;
    expect(server.status, 403);
    expect(server.message, 'Accès refusé');
  });

  test('5xx maps to ServerFailure with status and message', () {
    final failure = mapDio(
      dio(status: 500, data: {'error': 'Service unavailable'}),
    );
    expect(failure, isA<ServerFailure>());
    final server = failure as ServerFailure;
    expect(server.status, 500);
    expect(server.message, 'Service unavailable');
  });
}
