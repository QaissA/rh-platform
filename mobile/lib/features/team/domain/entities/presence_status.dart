enum PresenceStatus {
  onSite,
  remote,
  holiday;

  String get wire => switch (this) {
        onSite => 'on_site',
        remote => 'remote',
        holiday => 'holiday',
      };

  static PresenceStatus fromWire(String value) => switch (value) {
        'on_site' => onSite,
        'remote' => remote,
        'holiday' => holiday,
        _ => throw FormatException('Unknown presence status: $value'),
      };
}

enum DeclarableStatus {
  onSite,
  remote;

  String get wire => switch (this) {
        onSite => 'on_site',
        remote => 'remote',
      };
}
