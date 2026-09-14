import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_balance.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/repositories/leave_repository.dart';
import 'package:alize_mobile/features/leave/presentation/pages/leave_review_page.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/people_directory.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart' as format;
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeLeaveRepository implements LeaveRepository {
  FakeLeaveRepository({this.team = const []});

  List<LeaveRequest> team;
  List<LeaveStatus>? lastStatus;
  int teamCalls = 0;
  int approveCalls = 0;
  int rejectCalls = 0;
  String? lastRejectComment;

  @override
  Future<Result<LeaveBalance>> getBalance() async =>
      const Result.ok(LeaveBalance(userId: 1, daysRemaining: 18));

  @override
  Future<Result<List<LeaveRequest>>> getMyRequests() async =>
      const Result.ok([]);

  @override
  Future<Result<LeaveRequest>> create(NewLeaveRequest request) async {
    return const Result.err(Failure.network());
  }

  @override
  Future<Result<List<LeaveRequest>>> getTeamRequests({
    List<LeaveStatus>? status,
  }) async {
    teamCalls++;
    lastStatus = status;
    if (status == null || status.isEmpty) return Result.ok(team);
    final wanted = status.toSet();
    return Result.ok(team.where((r) => wanted.contains(r.status)).toList());
  }

  @override
  Future<Result<LeaveRequest>> approve(int id) async {
    approveCalls++;
    LeaveRequest? updated;
    team = [
      for (final request in team)
        if (request.id == id)
          updated = LeaveRequest(
            id: request.id,
            userId: request.userId,
            teamId: request.teamId,
            startDate: request.startDate,
            endDate: request.endDate,
            status: request.status == LeaveStatus.pending
                ? LeaveStatus.pendingHr
                : LeaveStatus.approved,
            reason: request.reason,
            days: request.days,
          )
        else
          request,
    ];
    return Result.ok(updated!);
  }

  @override
  Future<Result<LeaveRequest>> reject(int id, {String? comment}) async {
    rejectCalls++;
    lastRejectComment = comment;
    LeaveRequest? updated;
    team = [
      for (final request in team)
        if (request.id == id)
          updated = LeaveRequest(
            id: request.id,
            userId: request.userId,
            teamId: request.teamId,
            startDate: request.startDate,
            endDate: request.endDate,
            status: LeaveStatus.rejected,
            reason: request.reason,
            days: request.days,
            decisionComment: comment,
          )
        else
          request,
    ];
    return Result.ok(updated!);
  }
}

class FakePeopleDirectory implements PeopleDirectory {
  FakePeopleDirectory(this.members);

  final Map<int, TeamMember> members;

  @override
  Future<Result<Map<int, TeamMember>>> load() async => Result.ok(members);

  @override
  TeamMember? get(int id) => members[id];

  @override
  String nameOf(int id) {
    final member = get(id);
    return member == null ? 'Collaborateur #$id' : format.fullName(member);
  }

  @override
  String? jobTitleOf(int id) => format.jobTitleOf(get(id));

  @override
  String initialsOf(int id) {
    final member = get(id);
    return member == null ? '?' : format.initialsOf(member);
  }

  @override
  TeamMember toMember(User user) {
    return TeamMember(
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      jobTitle: user.jobTitle,
    );
  }
}

class _SignedInAuth extends AuthNotifier {
  _SignedInAuth(this.role);

  final String role;

  @override
  AuthState build() => AuthSignedIn(
        Session(
          token: 'jwt',
          user: User(
            id: 1,
            email: 'ada@rh.local',
            role: role,
            firstName: 'Ada',
            lastName: 'Lovelace',
            jobTitle: 'Dev',
          ),
        ),
      );
}

class TrackingInboxBadge extends InboxBadgeNotifier {
  int refreshCalls = 0;

  @override
  InboxBadgeState build() => const InboxBadgeState();

  @override
  Future<void> refresh() async {
    refreshCalls++;
  }
}

const _alan = TeamMember(
  id: 8,
  email: 'alan@rh.local',
  role: 'employee',
  firstName: 'Alan',
  lastName: 'Turing',
  jobTitle: 'Dev',
);

const _grace = TeamMember(
  id: 9,
  email: 'grace@rh.local',
  role: 'employee',
  firstName: 'Grace',
  lastName: 'Hopper',
  jobTitle: 'Lead',
);

const _pending = LeaveRequest(
  id: 44,
  userId: 8,
  teamId: 3,
  startDate: '2026-09-15',
  endDate: '2026-09-17',
  status: LeaveStatus.pending,
  reason: 'paid',
  days: 3,
);

const _pendingHr = LeaveRequest(
  id: 55,
  userId: 9,
  teamId: 3,
  startDate: '2026-09-22',
  endDate: '2026-09-23',
  status: LeaveStatus.pendingHr,
  reason: 'rtt',
  days: 2,
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  Future<TrackingInboxBadge> pumpReview(
    WidgetTester tester, {
    required String role,
    required FakeLeaveRepository leave,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final badges = TrackingInboxBadge();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          authProvider.overrideWith(() => _SignedInAuth(role)),
          leaveRepositoryProvider.overrideWithValue(leave),
          peopleDirectoryProvider.overrideWithValue(
            FakePeopleDirectory(const {8: _alan, 9: _grace}),
          ),
          inboxBadgeProvider.overrideWith(() => badges),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const LeaveReviewPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return badges;
  }

  testWidgets('manager sees pending request and Approuver', (tester) async {
    final leave = FakeLeaveRepository(team: const [_pending, _pendingHr]);
    await pumpReview(tester, role: 'manager', leave: leave);

    expect(leave.lastStatus, [LeaveStatus.pending]);
    expect(find.text('Alan Turing'), findsOneWidget);
    expect(find.text(i18n.t('common.approve')), findsOneWidget);
    expect(find.text('Grace Hopper'), findsNothing);
    expect(find.text(i18n.t('leaveReview.confirmLeave')), findsNothing);
    expect(find.text(i18n.t('stepper.manager')), findsWidgets);
    expect(find.text(i18n.t('stepper.hr')), findsWidgets);
  });

  testWidgets('rh does not treat pending as actionable', (tester) async {
    final leave = FakeLeaveRepository(team: const [_pending, _pendingHr]);
    await pumpReview(tester, role: 'rh', leave: leave);

    expect(leave.lastStatus, [LeaveStatus.pendingHr]);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text(i18n.t('leaveReview.confirmLeave')), findsOneWidget);
    expect(find.text('Alan Turing'), findsNothing);
    expect(find.text(i18n.t('common.approve')), findsNothing);

    await tester.tap(find.text(i18n.t('common.all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(leave.lastStatus, isNull);
    expect(find.text('Alan Turing'), findsOneWidget);
    expect(find.text('Grace Hopper'), findsOneWidget);
    expect(find.text(i18n.t('common.approve')), findsNothing);
    expect(find.text(i18n.t('leaveReview.confirmLeave')), findsOneWidget);
    expect(find.text(i18n.t('common.treated')), findsOneWidget);
  });

  testWidgets('approve calls repo then list and inbox badge refresh',
      (tester) async {
    final leave = FakeLeaveRepository(team: const [_pending]);
    final badges = await pumpReview(tester, role: 'manager', leave: leave);

    expect(leave.teamCalls, 1);
    await tester.tap(find.text(i18n.t('common.approve')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(leave.approveCalls, 1);
    expect(leave.teamCalls, greaterThan(1));
    expect(leave.lastStatus, [LeaveStatus.pending]);
    expect(find.text(i18n.t('common.approve')), findsNothing);
    expect(find.text(i18n.t('leaveReview.emptyPending')), findsOneWidget);
    expect(badges.refreshCalls, 1);
  });
}
