import 'dart:async';

import 'package:alize_mobile/features/admin_projects/data/datasources/project_admin_remote.dart';
import 'package:alize_mobile/features/admin_projects/data/repositories/project_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/project.dart';
import 'package:alize_mobile/features/admin_projects/domain/repositories/project_admin_repository.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final projectAdminRemoteProvider = Provider<ProjectAdminRemote>(
  (ref) => ProjectAdminRemote(ref.watch(dioProvider)),
);

final projectAdminRepositoryProvider = Provider<ProjectAdminRepository>(
  (ref) => ProjectAdminRepositoryImpl(
    remote: ref.watch(projectAdminRemoteProvider),
  ),
);

class AdminProjectsState {
  const AdminProjectsState({
    this.loading = true,
    this.projects = const [],
    this.filterBuId,
  });

  final bool loading;
  final List<Project> projects;
  final int? filterBuId;

  AdminProjectsState copyWith({
    bool? loading,
    List<Project>? projects,
    int? filterBuId,
    bool clearFilter = false,
  }) {
    return AdminProjectsState(
      loading: loading ?? this.loading,
      projects: projects ?? this.projects,
      filterBuId: clearFilter ? null : (filterBuId ?? this.filterBuId),
    );
  }
}

final adminProjectsControllerProvider =
    NotifierProvider<AdminProjectsController, AdminProjectsState>(
  AdminProjectsController.new,
);

class AdminProjectsController extends Notifier<AdminProjectsState> {
  bool _disposed = false;

  @override
  AdminProjectsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const AdminProjectsState();
  }

  Future<void> setFilter(int? businessUnitId) async {
    state = state.copyWith(
      loading: true,
      filterBuId: businessUnitId,
      clearFilter: businessUnitId == null,
    );
    await _load();
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true);
    await _load();
  }

  Future<void> _load() async {
    final result = await ref.read(projectAdminRepositoryProvider).list(
          businessUnitId: state.filterBuId,
        );
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      projects: result.data ?? const [],
    );
  }
}
