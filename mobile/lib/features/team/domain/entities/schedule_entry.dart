import 'presence_status.dart';

class ScheduleEntry {
  const ScheduleEntry({
    required this.userId,
    required this.date,
    required this.status,
  });

  final int userId;
  final String date;
  final PresenceStatus status;
}

class ScheduleSnapshot {
  const ScheduleSnapshot({
    required this.start,
    required this.end,
    required this.entries,
  });

  final String start;
  final String end;
  final List<ScheduleEntry> entries;
}
