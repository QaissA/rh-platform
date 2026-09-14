import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/presentation/providers/leave_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InboxBadgeState {
  const InboxBadgeState({this.leaveQueue = 0, this.docQueue = 0});

  final int leaveQueue;
  final int docQueue;
}

final inboxBadgeProvider =
    NotifierProvider<InboxBadgeNotifier, InboxBadgeState>(
  InboxBadgeNotifier.new,
);

class InboxBadgeNotifier extends Notifier<InboxBadgeState> {
  bool _disposed = false;

  @override
  InboxBadgeState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthSignedOut) {
        state = const InboxBadgeState();
      }
    });
    return const InboxBadgeState();
  }

  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    if (auth is! AuthSignedIn) {
      state = const InboxBadgeState();
      return;
    }
    final role = auth.session.user.role;
    final leaveFuture = _leaveQueue(role);
    final docFuture = _docQueue(role);
    final leaveQueue = await leaveFuture;
    final docQueue = await docFuture;
    if (_disposed || ref.read(authProvider) is AuthSignedOut) return;
    state = InboxBadgeState(leaveQueue: leaveQueue, docQueue: docQueue);
  }

  Future<int> _leaveQueue(String role) async {
    final status = switch (role) {
      'manager' => const [LeaveStatus.pending],
      'rh' => const [LeaveStatus.pendingHr],
      'admin' => const [LeaveStatus.pending, LeaveStatus.pendingHr],
      _ => null,
    };
    if (status == null) return 0;
    final result = await ref.read(leaveRepositoryProvider).getTeamRequests(
          status: status,
        );
    if (!result.isOk || result.data == null) return 0;
    return result.data!.length;
  }

  Future<int> _docQueue(String role) async {
    if (role != 'rh' && role != 'admin') return 0;
    final result = await ref.read(documentRepositoryProvider).getInbox();
    if (!result.isOk || result.data == null) return 0;
    return result.data!.where((r) => r.status.isOpen).length;
  }
}
