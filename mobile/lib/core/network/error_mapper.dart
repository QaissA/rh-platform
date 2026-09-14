import 'package:alize_mobile/core/error/failures.dart';
import 'package:dio/dio.dart';

Failure mapDio(DioException e) {
  final status = e.response?.statusCode;
  final message = _messageFrom(e.response?.data);

  if (status == 401) return const UnauthorizedFailure();
  if (status == 404) return const NotFoundFailure();
  if (status == 422) return ValidationFailure(message ?? '');
  if (status != null && status >= 400) {
    return ServerFailure(status: status, message: message);
  }
  return const NetworkFailure();
}

String? _messageFrom(dynamic data) {
  if (data is! Map) return null;
  final error = data['error'];
  if (error is String && error.isNotEmpty) return error;
  final errors = data['errors'];
  if (errors is List && errors.isNotEmpty) return errors.join(', ');
  if (errors is String && errors.isNotEmpty) return errors;
  return null;
}
