import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ok unwraps data', () {
    const r = Result.ok(7);
    expect(r.isOk, isTrue);
    expect(r.data, 7);
  });

  test('err unwraps failure', () {
    const r = Result<int>.err(Failure.unauthorized());
    expect(r.isOk, isFalse);
    expect(r.failure, isA<UnauthorizedFailure>());
  });
}
