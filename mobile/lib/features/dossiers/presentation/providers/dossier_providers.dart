import 'dart:async';

import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/dossiers/data/datasources/dossier_remote.dart';
import 'package:alize_mobile/features/dossiers/data/repositories/dossier_repository_impl.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/user_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/repositories/dossier_repository.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dossierRemoteProvider = Provider<DossierRemote>(
  (ref) => DossierRemote(ref.watch(dioProvider)),
);

final dossierRepositoryProvider = Provider<DossierRepository>(
  (ref) => DossierRepositoryImpl(remote: ref.watch(dossierRemoteProvider)),
);

class DossiersState {
  const DossiersState({
    this.loading = true,
    this.users = const [],
    this.busyId,
  });

  final bool loading;
  final List<TeamMember> users;
  final int? busyId;

  List<TeamMember> get pending => users
      .where((u) => (u.pendingJobTitle ?? '').trim().isNotEmpty)
      .toList(growable: false);

  DossiersState copyWith({
    bool? loading,
    List<TeamMember>? users,
    int? busyId,
    bool clearBusy = false,
  }) {
    return DossiersState(
      loading: loading ?? this.loading,
      users: users ?? this.users,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
    );
  }
}

final dossiersControllerProvider =
    NotifierProvider<DossiersController, DossiersState>(
  DossiersController.new,
);

class DossiersController extends Notifier<DossiersState> {
  bool _disposed = false;

  @override
  DossiersState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const DossiersState();
  }

  Future<void> reload({bool showSpinner = true}) async {
    if (showSpinner) {
      state = state.copyWith(loading: true);
    }
    await _load();
  }

  Future<void> _load() async {
    final result = await ref.read(peopleDirectoryProvider).load();
    if (_disposed) return;
    final users = result.data?.values.toList(growable: false) ?? state.users;
    state = state.copyWith(loading: false, users: users, clearBusy: true);
  }

  Future<Result<UserDossier>> acceptJobTitle(TeamMember user) async {
    state = state.copyWith(busyId: user.id);
    final result =
        await ref.read(dossierRepositoryProvider).acceptJobTitle(user.id);
    if (_disposed) return result;
    if (result.isOk) {
      await reload(showSpinner: false);
    } else {
      state = state.copyWith(clearBusy: true);
    }
    return result;
  }

  Future<Result<UserDossier>> rejectJobTitle(
    TeamMember user, {
    String? comment,
  }) async {
    state = state.copyWith(busyId: user.id);
    final result = await ref.read(dossierRepositoryProvider).rejectJobTitle(
          user.id,
          comment: comment,
        );
    if (_disposed) return result;
    if (result.isOk) {
      await reload(showSpinner: false);
    } else {
      state = state.copyWith(clearBusy: true);
    }
    return result;
  }
}

String memberName(TeamMember user) => fullName(user);
