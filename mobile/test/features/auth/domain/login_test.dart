import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:alize_mobile/features/auth/domain/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late Login login;

  const user = User(
    id: 1,
    email: 'a@b.com',
    role: 'employee',
    teamId: 2,
    businessUnitId: 3,
    projectId: 4,
    firstName: 'Ada',
    lastName: 'Lovelace',
    jobTitle: 'Engineer',
    pendingJobTitle: null,
    mustChangePassword: false,
  );

  const session = Session(token: 'jwt', user: user);

  setUp(() {
    repo = MockAuthRepository();
    login = Login(repo);
  });

  test('returns session when repository succeeds', () async {
    when(
      () => repo.login(email: 'a@b.com', password: 'secret'),
    ).thenAnswer((_) async => const Result.ok(session));

    final result = await login('a@b.com', 'secret');

    expect(result.isOk, isTrue);
    expect(result.data, session);
  });

  test('returns same error when repository fails', () async {
    const failure = Failure.unauthorized();
    when(
      () => repo.login(email: 'a@b.com', password: 'secret'),
    ).thenAnswer((_) async => const Result.err(failure));

    final result = await login('a@b.com', 'secret');

    expect(result.isOk, isFalse);
    expect(result.failure, failure);
  });
}
