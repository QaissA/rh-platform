import 'failures.dart';

class Result<T> {
  const Result._({this.data, this.failure});
  const Result.ok(T data) : this._(data: data);
  const Result.err(Failure failure) : this._(failure: failure);

  final T? data;
  final Failure? failure;

  bool get isOk => failure == null;
}
