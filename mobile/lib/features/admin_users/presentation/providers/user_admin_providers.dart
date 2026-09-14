import 'dart:async';

import 'package:alize_mobile/features/admin_users/data/datasources/user_admin_remote.dart';
import 'package:alize_mobile/features/admin_users/data/repositories/user_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_users/domain/repositories/user_admin_repository.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userAdminRemoteProvider = Provider<UserAdminRemote>(
  (ref) => UserAdminRemote(ref.watch(dioProvider)),
);

final userAdminRepositoryProvider = Provider<UserAdminRepository>(
  (ref) => UserAdminRepositoryImpl(remote: ref.watch(userAdminRemoteProvider)),
);

class AdminUsersState {
  const AdminUsersState({
    this.loading = true,
    this.users = const [],
  });

  final bool loading;
  final List<User> users;

  AdminUsersState copyWith({
    bool? loading,
    List<User>? users,
  }) {
    return AdminUsersState(
      loading: loading ?? this.loading,
      users: users ?? this.users,
    );
  }
}

final adminUsersControllerProvider =
    NotifierProvider<AdminUsersController, AdminUsersState>(
  AdminUsersController.new,
);

class AdminUsersController extends Notifier<AdminUsersState> {
  bool _disposed = false;

  @override
  AdminUsersState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const AdminUsersState();
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true);
    await _load();
  }

  Future<void> _load() async {
    final result = await ref.read(userAdminRepositoryProvider).list();
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      users: result.data ?? const [],
    );
  }
}
