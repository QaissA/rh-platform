import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_status.dart';

class LeaveRequestDto {
  const LeaveRequestDto({
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
  final String status;
  final String? reason;
  final int? days;
  final int? decidedBy;
  final String? decidedAt;
  final String? decisionComment;

  factory LeaveRequestDto.fromJson(Map<String, dynamic> json) {
    return LeaveRequestDto(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      teamId: json['team_id'] as int?,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String?,
      days: (json['days'] as num?)?.toInt(),
      decidedBy: json['decided_by'] as int?,
      decidedAt: json['decided_at'] as String?,
      decisionComment: json['decision_comment'] as String?,
    );
  }

  LeaveRequest toDomain() => LeaveRequest(
        id: id,
        userId: userId,
        teamId: teamId,
        startDate: startDate,
        endDate: endDate,
        status: LeaveStatus.fromWire(status),
        reason: reason,
        days: days,
        decidedBy: decidedBy,
        decidedAt: decidedAt,
        decisionComment: decisionComment,
      );
}
