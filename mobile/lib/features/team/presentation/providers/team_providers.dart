import 'dart:async';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/team/data/datasources/schedule_remote.dart';
import 'package:alize_mobile/features/team/data/datasources/team_remote.dart';
import 'package:alize_mobile/features/team/data/datasources/users_remote.dart';
import 'package:alize_mobile/features/team/data/repositories/people_directory_impl.dart';
import 'package:alize_mobile/features/team/data/repositories/schedule_repository_impl.dart';
import 'package:alize_mobile/features/team/data/repositories/team_repository_impl.dart';
import 'package:alize_mobile/features/team/domain/entities/my_team.dart';
import 'package:alize_mobile/features/team/domain/entities/new_presence.dart';
import 'package:alize_mobile/features/team/domain/entities/presence_status.dart';
import 'package:alize_mobile/features/team/domain/entities/schedule_entry.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/people_directory.dart';
import 'package:alize_mobile/features/team/domain/repositories/schedule_repository.dart';
import 'package:alize_mobile/features/team/domain/repositories/team_repository.dart';
import 'package:alize_mobile/features/team/domain/usecases/declare_presence.dart';
import 'package:alize_mobile/features/team/domain/usecases/get_my_team.dart';
import 'package:alize_mobile/features/team/domain/usecases/get_schedule.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamRemoteProvider = Provider<TeamRemote>(
  (ref) => TeamRemote(ref.watch(dioProvider)),
);

final scheduleRemoteProvider = Provider<ScheduleRemote>(
  (ref) => ScheduleRemote(ref.watch(dioProvider)),
);

final usersRemoteProvider = Provider<UsersRemote>(
  (ref) => UsersRemote(ref.watch(dioProvider)),
);

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepositoryImpl(remote: ref.watch(teamRemoteProvider)),
);

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepositoryImpl(remote: ref.watch(scheduleRemoteProvider)),
);

final peopleDirectoryProvider = Provider<PeopleDirectory>((ref) {
  final i18n = ref.watch(i18nProvider);
  return PeopleDirectoryImpl(
    teamRepository: ref.watch(teamRepositoryProvider),
    usersRemote: ref.watch(usersRemoteProvider),
    currentUser: () {
      final auth = ref.read(authProvider);
      if (auth is AuthSignedIn) return auth.session.user;
      return null;
    },
    collaboratorName: (id) => i18n.t('common.collaboratorN', {'id': id}),
  );
});

final getMyTeamProvider = Provider(
  (ref) => GetMyTeam(ref.watch(teamRepositoryProvider)),
);

final getScheduleProvider = Provider(
  (ref) => GetSchedule(ref.watch(scheduleRepositoryProvider)),
);

final declarePresenceProvider = Provider(
  (ref) => DeclarePresence(ref.watch(scheduleRepositoryProvider)),
);

class TeamViewState {
  const TeamViewState({
    this.loading = true,
    this.submitting = false,
    this.panelOpen = false,
    this.hasTeam = true,
    this.teamName = '',
    this.roster = const [],
    this.entries = const [],
    required this.visibleMonth,
    this.declStart,
    this.declEnd,
    this.declStatus = DeclarableStatus.remote,
  });

  final bool loading;
  final bool submitting;
  final bool panelOpen;
  final bool hasTeam;
  final String teamName;
  final List<TeamMember> roster;
  final List<ScheduleEntry> entries;
  final DateTime visibleMonth;
  final String? declStart;
  final String? declEnd;
  final DeclarableStatus declStatus;

  Map<String, PresenceStatus> get statusByKey => {
        for (final e in entries) '${e.userId}|${e.date}': e.status,
      };

  TeamViewState copyWith({
    bool? loading,
    bool? submitting,
    bool? panelOpen,
    bool? hasTeam,
    String? teamName,
    List<TeamMember>? roster,
    List<ScheduleEntry>? entries,
    DateTime? visibleMonth,
    String? declStart,
    String? declEnd,
    DeclarableStatus? declStatus,
    bool clearDeclStart = false,
    bool clearDeclEnd = false,
  }) {
    return TeamViewState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      panelOpen: panelOpen ?? this.panelOpen,
      hasTeam: hasTeam ?? this.hasTeam,
      teamName: teamName ?? this.teamName,
      roster: roster ?? this.roster,
      entries: entries ?? this.entries,
      visibleMonth: visibleMonth ?? this.visibleMonth,
      declStart: clearDeclStart ? null : (declStart ?? this.declStart),
      declEnd: clearDeclEnd ? null : (declEnd ?? this.declEnd),
      declStatus: declStatus ?? this.declStatus,
    );
  }
}

final teamControllerProvider =
    NotifierProvider<TeamController, TeamViewState>(TeamController.new);

class TeamController extends Notifier<TeamViewState> {
  bool _disposed = false;
  int _scheduleReq = 0;

  @override
  TeamViewState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    final now = DateTime.now();
    unawaited(_load());
    return TeamViewState(visibleMonth: DateTime(now.year, now.month));
  }

  Future<void> reload() => _load(showSpinner: true);

  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner) {
      state = state.copyWith(loading: true);
    }
    final team = await ref.read(teamRepositoryProvider).getMine();
    if (_disposed) return;
    if (team.isOk && team.data != null) {
      state = state.copyWith(
        hasTeam: team.data!.team != null,
        teamName: team.data!.team?.name ?? '',
        roster: _rosterWithSelf(team.data!),
      );
    } else {
      state = state.copyWith(hasTeam: false, roster: _selfOnly());
    }
    await _loadSchedule();
    if (_disposed) return;
    state = state.copyWith(loading: false);
  }

  Future<void> _loadSchedule() async {
    final token = ++_scheduleReq;
    final (start, end) = _gridRange(state.visibleMonth);
    final result = await ref.read(scheduleRepositoryProvider).getSchedule(
          start: isoDate(start),
          end: isoDate(end),
        );
    if (_disposed || token != _scheduleReq) return;
    state = state.copyWith(entries: result.data?.entries ?? state.entries);
  }

  List<TeamMember> _rosterWithSelf(MyTeam team) {
    final me = _meMember();
    final members = [...team.members];
    if (me == null) return members;
    return [
      me,
      ...members.where((m) => m.id != me.id),
    ];
  }

  List<TeamMember> _selfOnly() {
    final me = _meMember();
    return me == null ? const [] : [me];
  }

  TeamMember? _meMember() {
    final auth = ref.read(authProvider);
    if (auth is! AuthSignedIn) return null;
    final user = auth.session.user;
    return TeamMember(
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      jobTitle: user.jobTitle,
      pendingJobTitle: user.pendingJobTitle,
    );
  }

  void togglePanel() => state = state.copyWith(panelOpen: !state.panelOpen);

  void closePanel() => state = state.copyWith(panelOpen: false);

  void openDay(String iso) {
    state = state.copyWith(
      panelOpen: true,
      declStart: iso,
      declEnd: iso,
    );
  }

  void setDeclStart(String iso) => state = state.copyWith(declStart: iso);

  void setDeclEnd(String iso) => state = state.copyWith(declEnd: iso);

  void setDeclStatus(DeclarableStatus status) =>
      state = state.copyWith(declStatus: status);

  void shiftMonth(int delta) {
    final current = state.visibleMonth;
    state = state.copyWith(
      visibleMonth: DateTime(current.year, current.month + delta),
    );
    unawaited(_loadSchedule());
  }

  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(visibleMonth: DateTime(now.year, now.month));
    unawaited(_loadSchedule());
  }

  Future<Result<List<ScheduleEntry>>> submit() async {
    final start = state.declStart;
    if (state.submitting || start == null) {
      return const Result.err(Failure.validation(''));
    }
    state = state.copyWith(submitting: true);
    final result = await ref.read(declarePresenceProvider)(
      NewPresence(
        startDate: start,
        endDate: state.declEnd ?? start,
        status: state.declStatus,
      ),
    );
    if (_disposed) return result;
    if (result.isOk) {
      state = state.copyWith(submitting: false, panelOpen: false);
      await _loadSchedule();
    } else {
      state = state.copyWith(submitting: false);
    }
    return result;
  }
}

(DateTime, DateTime) _gridRange(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  final start = first.subtract(Duration(days: first.weekday - DateTime.monday));
  var end = last;
  while (end.weekday != DateTime.sunday) {
    end = DateTime(end.year, end.month, end.day + 1);
  }
  return (start, end);
}
