import 'dart:async';

import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/leave/data/datasources/leave_remote.dart';
import 'package:alize_mobile/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/repositories/leave_repository.dart';
import 'package:alize_mobile/features/leave/domain/usecases/approve_leave.dart';
import 'package:alize_mobile/features/leave/domain/usecases/create_leave_request.dart';
import 'package:alize_mobile/features/leave/domain/usecases/get_balance.dart';
import 'package:alize_mobile/features/leave/domain/usecases/get_my_requests.dart';
import 'package:alize_mobile/features/leave/domain/usecases/get_team_requests.dart';
import 'package:alize_mobile/features/leave/domain/usecases/reject_leave.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final leaveRemoteProvider = Provider<LeaveRemote>(
  (ref) => LeaveRemote(ref.watch(dioProvider)),
);

final leaveRepositoryProvider = Provider<LeaveRepository>(
  (ref) => LeaveRepositoryImpl(remote: ref.watch(leaveRemoteProvider)),
);

final getBalanceProvider = Provider(
  (ref) => GetBalance(ref.watch(leaveRepositoryProvider)),
);

final getMyRequestsProvider = Provider(
  (ref) => GetMyRequests(ref.watch(leaveRepositoryProvider)),
);

final createLeaveRequestProvider = Provider(
  (ref) => CreateLeaveRequest(ref.watch(leaveRepositoryProvider)),
);

final getTeamRequestsProvider = Provider(
  (ref) => GetTeamRequests(ref.watch(leaveRepositoryProvider)),
);

final approveLeaveProvider = Provider(
  (ref) => ApproveLeave(ref.watch(leaveRepositoryProvider)),
);

final rejectLeaveProvider = Provider(
  (ref) => RejectLeave(ref.watch(leaveRepositoryProvider)),
);

class LeaveViewState {
  const LeaveViewState({
    this.loading = true,
    this.submitting = false,
    this.formOpen = false,
    this.balanceDays = 0,
    this.requests = const [],
  });

  final bool loading;
  final bool submitting;
  final bool formOpen;
  final double balanceDays;
  final List<LeaveRequest> requests;

  LeaveViewState copyWith({
    bool? loading,
    bool? submitting,
    bool? formOpen,
    double? balanceDays,
    List<LeaveRequest>? requests,
  }) {
    return LeaveViewState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      formOpen: formOpen ?? this.formOpen,
      balanceDays: balanceDays ?? this.balanceDays,
      requests: requests ?? this.requests,
    );
  }
}

final leaveControllerProvider =
    NotifierProvider<LeaveController, LeaveViewState>(LeaveController.new);

class LeaveController extends Notifier<LeaveViewState> {
  bool _disposed = false;

  @override
  LeaveViewState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_load());
    return const LeaveViewState();
  }

  Future<void> reload() => _load(showSpinner: true);

  Future<void> _load({bool showSpinner = false}) async {
    if (showSpinner) {
      state = state.copyWith(loading: true);
    }
    final repo = ref.read(leaveRepositoryProvider);
    final balance = await repo.getBalance();
    final requests = await repo.getMyRequests();
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      balanceDays: balance.data?.daysRemaining ?? state.balanceDays,
      requests: requests.data ?? state.requests,
    );
  }

  void toggleForm() => state = state.copyWith(formOpen: !state.formOpen);

  void closeForm() => state = state.copyWith(formOpen: false);

  Future<Result<LeaveRequest>> submit(NewLeaveRequest request) async {
    state = state.copyWith(submitting: true);
    final result = await ref.read(createLeaveRequestProvider)(request);
    if (result.isOk) {
      state = state.copyWith(submitting: false, formOpen: false);
      await reload();
    } else {
      state = state.copyWith(submitting: false);
    }
    return result;
  }
}
