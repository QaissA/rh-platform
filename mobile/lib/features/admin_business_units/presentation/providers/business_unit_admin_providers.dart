import 'dart:async';

import 'package:alize_mobile/features/admin_business_units/data/datasources/business_unit_admin_remote.dart';
import 'package:alize_mobile/features/admin_business_units/data/repositories/business_unit_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/domain/repositories/business_unit_admin_repository.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final businessUnitAdminRemoteProvider = Provider<BusinessUnitAdminRemote>(
  (ref) => BusinessUnitAdminRemote(ref.watch(dioProvider)),
);

final businessUnitAdminRepositoryProvider =
    Provider<BusinessUnitAdminRepository>(
  (ref) => BusinessUnitAdminRepositoryImpl(
    remote: ref.watch(businessUnitAdminRemoteProvider),
  ),
);

class AdminBusinessUnitsState {
  const AdminBusinessUnitsState({
    this.loading = true,
    this.units = const [],
  });

  final bool loading;
  final List<BusinessUnit> units;

  AdminBusinessUnitsState copyWith({
    bool? loading,
    List<BusinessUnit>? units,
  }) {
    return AdminBusinessUnitsState(
      loading: loading ?? this.loading,
      units: units ?? this.units,
    );
  }
}

final adminBusinessUnitsControllerProvider =
    NotifierProvider<AdminBusinessUnitsController, AdminBusinessUnitsState>(
  AdminBusinessUnitsController.new,
);

class AdminBusinessUnitsController extends Notifier<AdminBusinessUnitsState> {
  bool _disposed = false;

  @override
  AdminBusinessUnitsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const AdminBusinessUnitsState();
  }

  Future<void> reload() async {
    state = state.copyWith(loading: true);
    await _load();
  }

  Future<void> _load() async {
    final result = await ref.read(businessUnitAdminRepositoryProvider).list();
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      units: result.data ?? const [],
    );
  }
}
