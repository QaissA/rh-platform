class NewLeaveRequest {
  const NewLeaveRequest({
    required this.startDate,
    required this.endDate,
    this.reason,
  });

  final String startDate;
  final String endDate;
  final String? reason;
}
