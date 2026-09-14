enum DocumentStatus {
  pending,
  processing,
  ready,
  rejected,
  cancelled;

  String get wire => switch (this) {
        pending => 'pending',
        processing => 'processing',
        ready => 'ready',
        rejected => 'rejected',
        cancelled => 'cancelled',
      };

  static DocumentStatus fromWire(String value) => switch (value) {
        'pending' => pending,
        'processing' => processing,
        'ready' => ready,
        'rejected' => rejected,
        'cancelled' => cancelled,
        _ => throw FormatException('Unknown document status: $value'),
      };

  bool get isOpen => this == pending || this == processing;
}
