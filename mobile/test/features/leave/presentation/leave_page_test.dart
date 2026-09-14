import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_balance.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/repositories/leave_repository.dart';
import 'package:alize_mobile/features/leave/presentation/pages/leave_page.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeLeaveRepository implements LeaveRepository {
  FakeLeaveRepository({
    this.balance = const LeaveBalance(userId: 1, daysRemaining: 18),
    this.requests = const [],
  });

  final LeaveBalance balance;
  final List<LeaveRequest> requests;

  @override
  Future<Result<LeaveBalance>> getBalance() async => Result.ok(balance);

  @override
  Future<Result<List<LeaveRequest>>> getMyRequests() async =>
      Result.ok(requests);

  @override
  Future<Result<LeaveRequest>> create(NewLeaveRequest request) async {
    return const Result.err(Failure.network());
  }

  @override
  Future<Result<List<LeaveRequest>>> getTeamRequests({
    List<LeaveStatus>? status,
  }) async {
    return const Result.ok([]);
  }

  @override
  Future<Result<LeaveRequest>> approve(int id) async {
    return const Result.err(Failure.network());
  }

  @override
  Future<Result<LeaveRequest>> reject(int id, {String? comment}) async {
    return const Result.err(Failure.network());
  }
}

const _pending = LeaveRequest(
  id: 11,
  userId: 1,
  teamId: 3,
  startDate: '2026-09-15',
  endDate: '2026-09-17',
  status: LeaveStatus.pending,
  reason: 'paid',
  days: 3,
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets(
    'fake repo with one pending request renders the range and status.leave.pending',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            i18nProvider.overrideWith((ref) => I18nController(i18n)),
            leaveRepositoryProvider.overrideWithValue(
              FakeLeaveRepository(requests: const [_pending]),
            ),
          ],
          child: MaterialApp(
            theme: AlizeTheme.light(),
            home: const LeavePage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(i18n.t('status.leave.pending'), 'En attente du manager');
      expect(find.text(i18n.t('status.leave.pending')), findsOneWidget);
      expect(find.text('15/09/2026 – 17/09/2026'), findsOneWidget);
    },
  );
}
