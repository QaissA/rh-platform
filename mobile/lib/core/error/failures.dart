sealed class Failure {
  const Failure();
  const factory Failure.network() = NetworkFailure;
  const factory Failure.unauthorized() = UnauthorizedFailure;
  const factory Failure.notFound() = NotFoundFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.server({int? status, String? message}) = ServerFailure;
}

class NetworkFailure extends Failure {
  const NetworkFailure();
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

class ValidationFailure extends Failure {
  const ValidationFailure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure({this.status, this.message});
  final int? status;
  final String? message;
}
