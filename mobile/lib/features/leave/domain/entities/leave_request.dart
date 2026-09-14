import 'leave_status.dart';

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.teamId,
    this.reason,
    this.days,
    this.decidedBy,
    this.decidedAt,
    this.decisionComment,
  });

  final int id;
  final int userId;
  final int? teamId;
  final String startDate;
  final String endDate;
  final LeaveStatus status;
  final String? reason;
  final int? days;
  final int? decidedBy;
  final String? decidedAt;
  final String? decisionComment;
}
