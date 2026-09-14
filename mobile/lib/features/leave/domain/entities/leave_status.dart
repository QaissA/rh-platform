enum LeaveStatus {
  pending,
  pendingHr,
  approved,
  rejected;

  String get wire => switch (this) {
        pending => 'pending',
        pendingHr => 'pending_hr',
        approved => 'approved',
        rejected => 'rejected',
      };

  static LeaveStatus fromWire(String value) => switch (value) {
        'pending' => pending,
        'pending_hr' => pendingHr,
        'approved' => approved,
        'rejected' => rejected,
        _ => throw FormatException('Unknown leave status: $value'),
      };

  bool get isAwaiting => this == pending || this == pendingHr;
}
