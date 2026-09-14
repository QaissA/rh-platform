import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/dashboard/presentation/pages/home_page.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:alize_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_balance.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/repositories/leave_repository.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/my_team.dart';
import 'package:alize_mobile/features/team/domain/entities/new_presence.dart';
import 'package:alize_mobile/features/team/domain/entities/presence_status.dart';
import 'package:alize_mobile/features/team/domain/entities/schedule_entry.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/people_directory.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart' as format;
import 'package:alize_mobile/features/team/domain/repositories/schedule_repository.dart';
import 'package:alize_mobile/features/team/domain/repositories/team_repository.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeLeaveRepository implements LeaveRepository {
  FakeLeaveRepository({
    this.balance = const LeaveBalance(userId: 1, daysRemaining: 18),
    this.requests = const [],
    this.teamPending = const [],
    this.teamPendingHr = const [],
    this.approveResult,
    this.rejectResult,
  });

  final LeaveBalance balance;
  final List<LeaveRequest> requests;
  List<LeaveRequest> teamPending;
  List<LeaveRequest> teamPendingHr;
  Result<LeaveRequest>? approveResult;
  Result<LeaveRequest>? rejectResult;
  int approveCalls = 0;
  int rejectCalls = 0;

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
    if (status == null || status.isEmpty) {
      return Result.ok([...teamPending, ...teamPendingHr]);
    }
    final wanted = status.toSet();
    final all = [...teamPending, ...teamPendingHr];
    return Result.ok(all.where((r) => wanted.contains(r.status)).toList());
  }

  @override
  Future<Result<LeaveRequest>> approve(int id) async {
    approveCalls++;
    final result = approveResult;
    if (result != null) return result;
    teamPending = teamPending.where((r) => r.id != id).toList();
    teamPendingHr = teamPendingHr.where((r) => r.id != id).toList();
    return Result.ok(
      LeaveRequest(
        id: id,
        userId: 8,
        startDate: '2026-09-15',
        endDate: '2026-09-17',
        status: LeaveStatus.pendingHr,
      ),
    );
  }

  @override
  Future<Result<LeaveRequest>> reject(int id, {String? comment}) async {
    rejectCalls++;
    final result = rejectResult;
    if (result != null) return result;
    teamPending = teamPending.where((r) => r.id != id).toList();
    teamPendingHr = teamPendingHr.where((r) => r.id != id).toList();
    return Result.ok(
      LeaveRequest(
        id: id,
        userId: 8,
        startDate: '2026-09-15',
        endDate: '2026-09-17',
        status: LeaveStatus.rejected,
      ),
    );
  }
}

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({
    this.mine = const [],
    this.inbox = const [],
  });

  final List<DocumentRequest> mine;
  final List<DocumentRequest> inbox;

  @override
  Future<Result<List<DocumentRequest>>> getRequests() async => Result.ok(mine);

  @override
  Future<Result<List<DocumentRequest>>> getInbox({String? status}) async =>
      Result.ok(inbox);

  @override
  Future<Result<DocumentRequest>> create(NewDocumentRequest request) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> getRequest(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> cancel(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> update(
    int id, {
    Map<String, String>? fields,
    String? status,
    String? decisionComment,
  }) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> reject(int id, {String? comment}) async =>
      const Result.err(Failure.network());
}

class FakeTeamRepository implements TeamRepository {
  FakeTeamRepository({required this.roster});

  final MyTeam roster;

  @override
  Future<Result<MyTeam>> getMine() async => Result.ok(roster);
}

class FakeScheduleRepository implements ScheduleRepository {
  FakeScheduleRepository({
    this.todayEntries = const [],
    this.weekEntries = const [],
  });

  final List<ScheduleEntry> todayEntries;
  final List<ScheduleEntry> weekEntries;

  @override
  Future<Result<ScheduleSnapshot>> getSchedule({
    required String start,
    required String end,
  }) async {
    final entries = start == end ? todayEntries : weekEntries;
    return Result.ok(ScheduleSnapshot(start: start, end: end, entries: entries));
  }

  @override
  Future<Result<List<ScheduleEntry>>> declarePresence(
    NewPresence presence,
  ) async {
    return const Result.err(Failure.network());
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
  _SignedInAuth({this.role = 'employee'});

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
  role: 'manager',
  firstName: 'Grace',
  lastName: 'Hopper',
);

LeaveRequest _leave({
  required int id,
  required LeaveStatus status,
  required String start,
  required String end,
  int userId = 1,
  String reason = 'paid',
  int? days,
}) {
  return LeaveRequest(
    id: id,
    userId: userId,
    teamId: 3,
    startDate: start,
    endDate: end,
    status: status,
    reason: reason,
    days: days,
  );
}

DocumentRequest _doc({
  required int id,
  required String type,
  required DocumentStatus status,
  int userId = 1,
}) {
  return DocumentRequest(
    id: id,
    userId: userId,
    docType: type,
    status: status,
  );
}

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  String todayIso() => isoDate(DateTime.now());

  String futureIso(int days) {
    final now = DateTime.now();
    return isoDate(DateTime(now.year, now.month, now.day + days));
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    String role = 'employee',
    LeaveRepository? leave,
    DocumentRepository? documents,
    MyTeam? team,
    List<ScheduleEntry> todayEntries = const [],
    List<ScheduleEntry> weekEntries = const [],
    Map<int, TeamMember>? people,
  }) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final roster = team ??
        const MyTeam(
          team: TeamRef(id: 3, name: 'Plateforme'),
          members: [_alan, _grace],
        );
    final directory = people ??
        {
          1: const TeamMember(
            id: 1,
            email: 'ada@rh.local',
            role: 'employee',
            firstName: 'Ada',
            lastName: 'Lovelace',
            jobTitle: 'Dev',
          ),
          8: _alan,
          9: _grace,
        };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          authProvider.overrideWith(() => _SignedInAuth(role: role)),
          leaveRepositoryProvider.overrideWithValue(
            leave ?? FakeLeaveRepository(),
          ),
          documentRepositoryProvider.overrideWithValue(
            documents ?? FakeDocumentRepository(),
          ),
          teamRepositoryProvider.overrideWithValue(
            FakeTeamRepository(roster: roster),
          ),
          scheduleRepositoryProvider.overrideWithValue(
            FakeScheduleRepository(
              todayEntries: todayEntries,
              weekEntries: weekEntries,
            ),
          ),
          peopleDirectoryProvider.overrideWithValue(
            FakePeopleDirectory(directory),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const HomePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets(
    'employee dashboard shows remaining days, next leave, last leaves, docs, team today and quick actions',
    (tester) async {
      final nextStart = futureIso(14);
      final nextEnd = futureIso(18);
      final pastStart = futureIso(-20);
      final pastEnd = futureIso(-18);

      await pumpHome(
        tester,
        leave: FakeLeaveRepository(
          requests: [
            _leave(
              id: 1,
              status: LeaveStatus.pending,
              start: futureIso(30),
              end: futureIso(32),
            ),
            _leave(
              id: 2,
              status: LeaveStatus.approved,
              start: nextStart,
              end: nextEnd,
              days: 5,
            ),
            _leave(
              id: 3,
              status: LeaveStatus.rejected,
              start: pastStart,
              end: pastEnd,
            ),
          ],
        ),
        documents: FakeDocumentRepository(
          mine: [
            _doc(
              id: 21,
              type: 'work_certificate',
              status: DocumentStatus.ready,
            ),
            _doc(
              id: 22,
              type: 'salary_certificate',
              status: DocumentStatus.pending,
            ),
          ],
        ),
        todayEntries: [
          ScheduleEntry(
            userId: 8,
            date: todayIso(),
            status: PresenceStatus.remote,
          ),
        ],
      );

      expect(find.text(i18n.t('dashboard.leaveBalance')), findsOneWidget);
      expect(find.text('18'), findsWidgets);
      expect(
        find.text(
          i18n.t('dashboard.nextLeave', {
            'range': formatRange(nextStart, nextEnd),
          }),
        ),
        findsOneWidget,
      );
      expect(find.text(formatRange(futureIso(30), futureIso(32))), findsOneWidget);
      expect(find.text(i18n.t('stepper.manager')), findsWidgets);
      expect(find.text(i18n.t('docType.work_certificate')), findsOneWidget);
      expect(find.text(i18n.t('dashboard.waitingRh', {'n': 1})), findsOneWidget);
      expect(find.text('Alan Turing'), findsOneWidget);
      expect(find.text(i18n.t('status.presence.remote')), findsOneWidget);
      expect(find.text(i18n.t('common.newRequest')), findsOneWidget);
      expect(find.text(i18n.t('dashboard.askDocument')), findsOneWidget);
      expect(find.text(i18n.t('dashboard.managerQueue')), findsNothing);
    },
  );

  testWidgets('employee empty states show a CTA', (tester) async {
    await pumpHome(
      tester,
      team: const MyTeam(team: null, members: []),
      people: const {},
    );

    expect(find.text(i18n.t('dashboard.noUpcoming')), findsOneWidget);
    expect(find.text(i18n.t('dashboard.noRequests')), findsOneWidget);
    expect(find.text(i18n.t('dashboard.requestLeave')), findsOneWidget);
    expect(find.text(i18n.t('dashboard.noDownload')), findsOneWidget);
    expect(find.text(i18n.t('dashboard.noTeam')), findsOneWidget);
  });

  testWidgets('shows skeleton loaders while the dashboard is loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          authProvider.overrideWith(_SignedInAuth.new),
          leaveRepositoryProvider.overrideWithValue(FakeLeaveRepository()),
          documentRepositoryProvider.overrideWithValue(
            FakeDocumentRepository(),
          ),
          teamRepositoryProvider.overrideWithValue(
            FakeTeamRepository(
              roster: const MyTeam(
                team: TeamRef(id: 3, name: 'Plateforme'),
                members: [_alan],
              ),
            ),
          ),
          scheduleRepositoryProvider.overrideWithValue(
            FakeScheduleRepository(),
          ),
          peopleDirectoryProvider.overrideWithValue(
            FakePeopleDirectory(const {8: _alan}),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const HomePage(),
        ),
      ),
    );

    expect(find.byKey(const Key('dashboard-skeleton')), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('dashboard-skeleton')), findsNothing);
  });

  testWidgets(
    'manager dashboard shows pending queue with approve/refuse and who is out this week',
    (tester) async {
      final pending = _leave(
        id: 44,
        userId: 8,
        status: LeaveStatus.pending,
        start: futureIso(7),
        end: futureIso(9),
        days: 3,
      );

      await pumpHome(
        tester,
        role: 'manager',
        leave: FakeLeaveRepository(teamPending: [pending]),
        weekEntries: [
          ScheduleEntry(
            userId: 9,
            date: todayIso(),
            status: PresenceStatus.holiday,
          ),
        ],
      );

      expect(find.text(i18n.t('dashboard.managerQueue')), findsOneWidget);
      expect(find.text('Alan Turing'), findsWidgets);
      expect(find.text(i18n.t('common.approve')), findsOneWidget);
      expect(find.text(i18n.t('common.reject')), findsOneWidget);
      expect(find.text(i18n.t('dashboard.thisWeek')), findsOneWidget);
      expect(find.text('Grace Hopper'), findsWidgets);
      expect(find.text(i18n.t('status.presence.holiday')), findsWidgets);
      expect(find.text(i18n.t('dashboard.hrConfirm')), findsNothing);
    },
  );

  testWidgets('manager approve calls the leave use case then refreshes', (
    tester,
  ) async {
    final pending = _leave(
      id: 44,
      userId: 8,
      status: LeaveStatus.pending,
      start: futureIso(7),
      end: futureIso(9),
      days: 3,
    );
    final leave = FakeLeaveRepository(teamPending: [pending]);

    await pumpHome(tester, role: 'manager', leave: leave);

    await tester.tap(find.text(i18n.t('common.approve')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(leave.approveCalls, 1);
    expect(find.text(i18n.t('dashboard.nothingToValidate')), findsOneWidget);
    expect(find.text(i18n.t('common.approve')), findsNothing);
  });

  testWidgets('approve failure shows a snackbar', (tester) async {
    final pending = _leave(
      id: 44,
      userId: 8,
      status: LeaveStatus.pending,
      start: futureIso(7),
      end: futureIso(9),
    );
    await pumpHome(
      tester,
      role: 'manager',
      leave: FakeLeaveRepository(
        teamPending: [pending],
        approveResult: const Result.err(Failure.network()),
      ),
    );

    await tester.tap(find.text(i18n.t('common.approve')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('leaveReview.approveFail')), findsOneWidget);
    expect(find.text(i18n.t('common.approve')), findsOneWidget);
  });

  testWidgets(
    'rh dashboard shows pending_hr queue, inbox count, latest docs and who is out today',
    (tester) async {
      final hrPending = _leave(
        id: 55,
        userId: 8,
        status: LeaveStatus.pendingHr,
        start: futureIso(7),
        end: futureIso(9),
        days: 3,
      );

      await pumpHome(
        tester,
        role: 'rh',
        leave: FakeLeaveRepository(teamPendingHr: [hrPending]),
        documents: FakeDocumentRepository(
          inbox: [
            _doc(
              id: 31,
              type: 'work_certificate',
              status: DocumentStatus.pending,
              userId: 8,
            ),
            _doc(
              id: 32,
              type: 'leave_attestation',
              status: DocumentStatus.processing,
              userId: 8,
            ),
            _doc(
              id: 33,
              type: 'salary_certificate',
              status: DocumentStatus.pending,
              userId: 8,
            ),
            _doc(
              id: 34,
              type: 'other',
              status: DocumentStatus.ready,
              userId: 8,
            ),
          ],
        ),
        todayEntries: [
          ScheduleEntry(
            userId: 8,
            date: todayIso(),
            status: PresenceStatus.holiday,
          ),
        ],
      );

      expect(find.text(i18n.t('dashboard.hrConfirm')), findsOneWidget);
      expect(find.text(i18n.t('leaveReview.confirmLeave')), findsOneWidget);
      expect(find.text(i18n.t('dashboard.docsToWrite')), findsOneWidget);
      expect(find.text('3'), findsWidgets);
      expect(find.text(i18n.t('docType.work_certificate')), findsOneWidget);
      expect(find.text(i18n.t('docType.leave_attestation')), findsOneWidget);
      expect(find.text(i18n.t('docType.salary_certificate')), findsOneWidget);
      expect(find.text(i18n.t('docType.other')), findsNothing);
      expect(find.text('Alan Turing'), findsWidgets);
      expect(find.text(i18n.t('status.presence.holiday')), findsWidgets);
      expect(find.text(i18n.t('dashboard.managerQueue')), findsNothing);
    },
  );
}
