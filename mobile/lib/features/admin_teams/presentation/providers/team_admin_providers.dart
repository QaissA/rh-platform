import 'dart:async';

import 'package:alize_mobile/features/admin_teams/data/datasources/team_admin_remote.dart';
import 'package:alize_mobile/features/admin_teams/data/repositories/team_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_summary.dart';
import 'package:alize_mobile/features/admin_teams/domain/repositories/team_admin_repository.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teamAdminRemoteProvider = Provider<TeamAdminRemote>(
  (ref) => TeamAdminRemote(ref.watch(dioProvider)),
);

final teamAdminRepositoryProvider = Provider<TeamAdminRepository>(
  (ref) => TeamAdminRepositoryImpl(remote: ref.watch(teamAdminRemoteProvider)),
);

class AdminTeamsState {
  const AdminTeamsState({
    this.loading = true,
    this.teams = const [],
  });

  final bool loading;
  final List<TeamSummary> teams;

  AdminTeamsState copyWith({
    bool? loading,
    List<TeamSummary>? teams,
  }) {
    return AdminTeamsState(
      loading: loading ?? this.loading,
      teams: teams ?? this.teams,
    );
  }
}

final adminTeamsControllerProvider =
    NotifierProvider<AdminTeamsController, AdminTeamsState>(
  AdminTeamsController.new,
);

class AdminTeamsController extends Notifier<AdminTeamsState> {
  bool _disposed = false;

  @override
  AdminTeamsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const AdminTeamsState();
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true);
    await _load();
  }

  Future<void> _load() async {
    final result = await ref.read(teamAdminRepositoryProvider).list();
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      teams: result.data ?? const [],
    );
  }
}
