import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:alize_mobile/features/auth/domain/usecases/change_password.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;
  late ChangePassword changePassword;

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

  setUp(() {
    repo = MockAuthRepository();
    changePassword = ChangePassword(repo);
  });

  test('returns user when repository succeeds', () async {
    when(
      () => repo.changePassword(
        currentPassword: 'old-pass',
        newPassword: 'new-pass',
      ),
    ).thenAnswer((_) async => const Result.ok(user));

    final result = await changePassword('old-pass', 'new-pass');

    expect(result.isOk, isTrue);
    expect(result.data, user);
  });

  test('returns same error when repository fails', () async {
    const failure = Failure.validation('Current password is incorrect');
    when(
      () => repo.changePassword(
        currentPassword: 'old-pass',
        newPassword: 'new-pass',
      ),
    ).thenAnswer((_) async => const Result.err(failure));

    final result = await changePassword('old-pass', 'new-pass');

    expect(result.isOk, isFalse);
    expect(result.failure, failure);
  });
}
