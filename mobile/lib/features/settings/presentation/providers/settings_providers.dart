import 'dart:async';

import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/settings/data/datasources/profile_remote.dart';
import 'package:alize_mobile/features/settings/data/repositories/profile_repository_impl.dart';
import 'package:alize_mobile/features/settings/domain/entities/update_profile.dart';
import 'package:alize_mobile/features/settings/domain/entities/user_profile.dart';
import 'package:alize_mobile/features/settings/domain/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRemoteProvider = Provider<ProfileRemote>(
  (ref) => ProfileRemote(ref.watch(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(remote: ref.watch(profileRemoteProvider)),
);

class SettingsViewState {
  const SettingsViewState({
    this.loading = true,
    this.profile,
    this.savingAddress = false,
    this.savingTitle = false,
    this.savingSig = false,
  });

  final bool loading;
  final UserProfile? profile;
  final bool savingAddress;
  final bool savingTitle;
  final bool savingSig;

  SettingsViewState copyWith({
    bool? loading,
    UserProfile? profile,
    bool? savingAddress,
    bool? savingTitle,
    bool? savingSig,
  }) {
    return SettingsViewState(
      loading: loading ?? this.loading,
      profile: profile ?? this.profile,
      savingAddress: savingAddress ?? this.savingAddress,
      savingTitle: savingTitle ?? this.savingTitle,
      savingSig: savingSig ?? this.savingSig,
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsViewState>(
  SettingsController.new,
);

class SettingsController extends Notifier<SettingsViewState> {
  bool _disposed = false;

  @override
  SettingsViewState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const SettingsViewState();
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    final result = await ref.read(profileRepositoryProvider).getMine();
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      profile: result.data ?? state.profile,
    );
  }

  Future<Result<UserProfile>> saveAddress({
    required String addressLine,
    required String postalCode,
    required String city,
    required String country,
  }) {
    return _update(
      saving: (value) => state = state.copyWith(savingAddress: value),
      payload: UpdateProfile(
        addressLine: addressLine,
        postalCode: postalCode,
        city: city,
        country: country.isEmpty ? 'FR' : country,
      ),
    );
  }

  Future<Result<UserProfile>> requestTitle(String title) {
    return _update(
      saving: (value) => state = state.copyWith(savingTitle: value),
      payload: UpdateProfile(pendingJobTitle: title),
    );
  }

  Future<Result<UserProfile>> cancelTitle() {
    return _update(
      saving: (value) => state = state.copyWith(savingTitle: value),
      payload: const UpdateProfile(clearPendingJobTitle: true),
    );
  }

  Future<Result<UserProfile>> saveSignature(String png) {
    return _update(
      saving: (value) => state = state.copyWith(savingSig: value),
      payload: UpdateProfile(signaturePng: png),
    );
  }

  Future<Result<UserProfile>> _update({
    required void Function(bool saving) saving,
    required UpdateProfile payload,
  }) async {
    saving(true);
    final result = await ref.read(profileRepositoryProvider).updateMine(payload);
    if (_disposed) return result;
    if (result.isOk && result.data != null) {
      saving(false);
      state = state.copyWith(profile: result.data);
    } else {
      saving(false);
    }
    return result;
  }
}
