import 'dart:async';

import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_request.dart';
import 'package:alize_mobile/features/leave/domain/leave_review_queue.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LeaveReviewFilter { pending, all }

class LeaveReviewState {
  const LeaveReviewState({
    this.loading = true,
    this.filter = LeaveReviewFilter.pending,
    this.requests = const [],
    this.busyId,
    this.rejectingId,
  });

  final bool loading;
  final LeaveReviewFilter filter;
  final List<LeaveRequest> requests;
  final int? busyId;
  final int? rejectingId;

  int pendingCount(String role) =>
      requests.where((r) => isLeaveActionable(role, r.status)).length;

  LeaveReviewState copyWith({
    bool? loading,
    LeaveReviewFilter? filter,
    List<LeaveRequest>? requests,
    int? busyId,
    int? rejectingId,
    bool clearBusy = false,
    bool clearRejecting = false,
  }) {
    return LeaveReviewState(
      loading: loading ?? this.loading,
      filter: filter ?? this.filter,
      requests: requests ?? this.requests,
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      rejectingId: clearRejecting ? null : (rejectingId ?? this.rejectingId),
    );
  }
}

final leaveReviewControllerProvider =
    NotifierProvider<LeaveReviewController, LeaveReviewState>(
  LeaveReviewController.new,
);

class LeaveReviewController extends Notifier<LeaveReviewState> {
  bool _disposed = false;

  @override
  LeaveReviewState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(ref.read(peopleDirectoryProvider).load());
    unawaited(_fetch(LeaveReviewFilter.pending));
    return const LeaveReviewState();
  }

  String get role {
    final auth = ref.read(authProvider);
    return auth is AuthSignedIn ? auth.session.user.role : '';
  }

  Future<void> reload({bool showSpinner = true}) async {
    if (showSpinner) {
      state = state.copyWith(loading: true);
    }
    await _fetch(state.filter);
  }

  Future<void> setFilter(LeaveReviewFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(
      filter: filter,
      loading: true,
      clearRejecting: true,
    );
    await _fetch(filter);
  }

  Future<void> _fetch(LeaveReviewFilter filter) async {
    final status = teamRequestStatusFilter(
      role: role,
      pendingOnly: filter == LeaveReviewFilter.pending,
    );
    final result = await ref.read(leaveRepositoryProvider).getTeamRequests(
          status: status,
        );
    if (_disposed) return;
    state = state.copyWith(
      loading: false,
      requests: result.data ?? state.requests,
    );
  }

  void askReject(int id) {
    state = state.copyWith(rejectingId: id);
  }

  void cancelReject() {
    state = state.copyWith(clearRejecting: true);
  }

  Future<Result<LeaveRequest>> approve(int id) => _decide(id, approve: true);

  Future<Result<LeaveRequest>> reject(int id, {String? comment}) =>
      _decide(id, approve: false, comment: comment);

  Future<Result<LeaveRequest>> _decide(
    int id, {
    required bool approve,
    String? comment,
  }) async {
    state = state.copyWith(busyId: id);
    final result = approve
        ? await ref.read(approveLeaveProvider)(id)
        : await ref.read(rejectLeaveProvider)(id, comment: comment);
    if (_disposed) return result;
    state = state.copyWith(clearBusy: true, clearRejecting: true);
    if (result.isOk) {
      await reload(showSpinner: false);
      if (!_disposed) {
        await ref.read(inboxBadgeProvider.notifier).refresh();
      }
    }
    return result;
  }
}
