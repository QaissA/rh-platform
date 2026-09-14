import 'entities/leave_status.dart';

/// Statuses a reviewer can act on, matching Angular `validation-conges`.
List<LeaveStatus> actionableLeaveStatuses(String role) {
  if (role == 'rh') return const [LeaveStatus.pendingHr];
  if (role == 'manager') return const [LeaveStatus.pending];
  return const [LeaveStatus.pending, LeaveStatus.pendingHr];
}

bool isLeaveActionable(String role, LeaveStatus status) =>
    actionableLeaveStatuses(role).contains(status);

/// `null` means fetch the whole team scope (Angular `filter === 'all'`).
List<LeaveStatus>? teamRequestStatusFilter({
  required String role,
  required bool pendingOnly,
}) {
  if (!pendingOnly) return null;
  return actionableLeaveStatuses(role);
}
