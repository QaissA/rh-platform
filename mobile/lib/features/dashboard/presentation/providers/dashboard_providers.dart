import 'dart:async';

import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/schedule_entry.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/people_directory.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardViewState {
  const DashboardViewState({
    this.loading = true,
    this.loadFailed = false,
    this.busyId,
    this.balanceDays = 0,
    this.requests = const [],
    this.documents = const [],
    this.teamName,
    this.roster = const [],
    this.todayEntries = const [],
    this.weekEntries = const [],
    this.managerQueue = const [],
    this.hrQueue = const [],
    this.inbox = const [],
  });

  final bool loading;
  final bool loadFailed;
  final int? busyId;
  final double balanceDays;
  final List<LeaveRequest> requests;
  final List<DocumentRequest> documents;
  final String? teamName;
  final List<TeamMember> roster;
  final List<ScheduleEntry> todayEntries;
  final List<ScheduleEntry> weekEntries;
  final List<LeaveRequest> managerQueue;
  final List<LeaveRequest> hrQueue;
  final List<DocumentRequest> inbox;

  DashboardViewState copyWith({
    bool? loading,
    bool? loadFailed,
    int? busyId,
    double? balanceDays,
    List<LeaveRequest>? requests,
    List<DocumentRequest>? documents,
    String? teamName,
    List<TeamMember>? roster,
    List<ScheduleEntry>? todayEntries,
    List<ScheduleEntry>? weekEntries,
    List<LeaveRequest>? managerQueue,
    List<LeaveRequest>? hrQueue,
    List<DocumentRequest>? inbox,
    bool clearBusy = false,
    bool clearTeamName = false,
  }) {
    return DashboardViewState(
      loading: loading ?? this.loading,
      loadFailed: loadFailed ?? this.loadFailed,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      balanceDays: balanceDays ?? this.balanceDays,
      requests: requests ?? this.requests,
      documents: documents ?? this.documents,
      teamName: clearTeamName ? null : (teamName ?? this.teamName),
      roster: roster ?? this.roster,
      todayEntries: todayEntries ?? this.todayEntries,
      weekEntries: weekEntries ?? this.weekEntries,
      managerQueue: managerQueue ?? this.managerQueue,
      hrQueue: hrQueue ?? this.hrQueue,
      inbox: inbox ?? this.inbox,
    );
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardViewState>(
  DashboardController.new,
);

class DashboardController extends Notifier<DashboardViewState> {
  bool _disposed = false;

  @override
  DashboardViewState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const DashboardViewState();
  }

  Future<void> reload() => _load();

  Future<Result<LeaveRequest>> approve(int id) => _decide(id, approve: true);

  Future<Result<LeaveRequest>> reject(int id) => _decide(id, approve: false);

  Future<Result<LeaveRequest>> _decide(int id, {required bool approve}) async {
    state = state.copyWith(busyId: id);
    final result = approve
        ? await ref.read(approveLeaveProvider)(id)
        : await ref.read(rejectLeaveProvider)(id);
    if (_disposed) return result;
    state = state.copyWith(clearBusy: true);
    if (result.isOk) {
      await _load();
    }
    return result;
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    final role = auth is AuthSignedIn ? auth.session.user.role : '';
    final showManager = role == 'manager' || role == 'admin';
    final showRh = role == 'rh' || role == 'admin';
    final today = isoDate(DateTime.now());
    final weekStart = startOfWeekIso();
    final weekEnd = addDaysIso(weekStart, 6);

    const emptyLeaves = Result<List<LeaveRequest>>.ok(<LeaveRequest>[]);
    const emptyDocs = Result<List<DocumentRequest>>.ok(<DocumentRequest>[]);

    final leave = ref.read(leaveRepositoryProvider);
    final docs = ref.read(documentRepositoryProvider);
    final team = ref.read(teamRepositoryProvider);
    final schedule = ref.read(scheduleRepositoryProvider);
    final people = ref.read(peopleDirectoryProvider);

    final balanceF = leave.getBalance();
    final requestsF = leave.getMyRequests();
    final documentsF = docs.getRequests();
    final mineF = team.getMine();
    final todayF = schedule.getSchedule(start: today, end: today);
    final weekF = schedule.getSchedule(start: weekStart, end: weekEnd);
    final pendingF = showManager
        ? leave.getTeamRequests(status: const [LeaveStatus.pending])
        : Future.value(emptyLeaves);
    final pendingHrF = showRh
        ? leave.getTeamRequests(status: const [LeaveStatus.pendingHr])
        : Future.value(emptyLeaves);
    final inboxF = showRh ? docs.getInbox() : Future.value(emptyDocs);
    final peopleF = people.load();

    try {
      final balance = await balanceF;
      final requests = await requestsF;
      final documents = await documentsF;
      final mine = await mineF;
      final todaySnap = await todayF;
      final weekSnap = await weekF;
      final pending = await pendingF;
      final pendingHr = await pendingHrF;
      final inbox = await inboxF;
      await peopleF;
      if (_disposed) return;

      final meId = auth is AuthSignedIn ? auth.session.user.id : null;
      state = state.copyWith(
        loading: false,
        loadFailed: false,
        balanceDays: balance.data?.daysRemaining ?? state.balanceDays,
        requests: requests.data ?? state.requests,
        documents: documents.data ?? state.documents,
        teamName: mine.data?.team?.name,
        clearTeamName: mine.data?.team == null,
        roster: _rosterFrom(meId, mine.data?.members ?? const [], people),
        todayEntries: todaySnap.data?.entries ?? state.todayEntries,
        weekEntries: weekSnap.data?.entries ?? state.weekEntries,
        managerQueue: pending.data ?? const [],
        hrQueue: pendingHr.data ?? const [],
        inbox: inbox.data ?? const [],
      );
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(loading: false, loadFailed: true);
    }
  }

  List<TeamMember> _rosterFrom(
    int? meId,
    List<TeamMember> members,
    PeopleDirectory people,
  ) {
    final list = [...members];
    final me = meId == null ? null : people.get(meId);
    if (me != null && !list.any((m) => m.id == me.id)) {
      list.insert(0, me);
    }
    return list;
  }
}
