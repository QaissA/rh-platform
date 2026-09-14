import '../../domain/entities/leave_balance.dart';

class LeaveBalanceDto {
  const LeaveBalanceDto({
    required this.userId,
    required this.daysRemaining,
  });

  final int userId;
  final double daysRemaining;

  factory LeaveBalanceDto.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceDto(
      userId: json['user_id'] as int,
      daysRemaining: _parseDays(json['days_remaining']),
    );
  }

  LeaveBalance toDomain() => LeaveBalance(
        userId: userId,
        daysRemaining: daysRemaining,
      );
}

double _parseDays(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
