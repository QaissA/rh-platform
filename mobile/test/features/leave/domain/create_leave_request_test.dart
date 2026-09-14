import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/repositories/leave_repository.dart';
import 'package:alize_mobile/features/leave/domain/usecases/create_leave_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaveRepository extends Mock implements LeaveRepository {}

void main() {
  late MockLeaveRepository repo;
  late CreateLeaveRequest create;

  const payload = NewLeaveRequest(
    startDate: '2026-09-15',
    endDate: '2026-09-17',
    reason: 'paid',
  );

  const created = LeaveRequest(
    id: 11,
    userId: 7,
    teamId: 3,
    startDate: '2026-09-15',
    endDate: '2026-09-17',
    status: LeaveStatus.pending,
    reason: 'paid',
    days: 3,
  );

  setUpAll(() {
    registerFallbackValue(payload);
  });

  setUp(() {
    repo = MockLeaveRepository();
    create = CreateLeaveRequest(repo);
  });

  test('returns created request when repository succeeds', () async {
    when(() => repo.create(payload)).thenAnswer((_) async => const Result.ok(created));

    final result = await create(payload);

    expect(result.isOk, isTrue);
    expect(result.data, created);
    verify(() => repo.create(payload)).called(1);
  });

  test('returns same error when repository fails', () async {
    const failure = Failure.validation('Dates invalides');
    when(() => repo.create(payload)).thenAnswer((_) async => const Result.err(failure));

    final result = await create(payload);

    expect(result.isOk, isFalse);
    expect(result.failure, failure);
  });
}
