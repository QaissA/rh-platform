import '../../domain/entities/presence_status.dart';
import '../../domain/entities/schedule_entry.dart';

class ScheduleEntryDto {
  const ScheduleEntryDto({
    required this.userId,
    required this.date,
    required this.status,
  });

  final int userId;
  final String date;
  final String status;

  factory ScheduleEntryDto.fromJson(Map<String, dynamic> json) {
    return ScheduleEntryDto(
      userId: json['user_id'] as int,
      date: json['date'] as String,
      status: json['status'] as String,
    );
  }

  ScheduleEntry toDomain() => ScheduleEntry(
        userId: userId,
        date: date,
        status: PresenceStatus.fromWire(status),
      );
}

class ScheduleSnapshotDto {
  const ScheduleSnapshotDto({
    required this.start,
    required this.end,
    required this.entries,
  });

  final String start;
  final String end;
  final List<ScheduleEntryDto> entries;

  factory ScheduleSnapshotDto.fromJson(Map<String, dynamic> json) {
    return ScheduleSnapshotDto(
      start: json['start'] as String,
      end: json['end'] as String,
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .map(
            (e) =>
                ScheduleEntryDto.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  ScheduleSnapshot toDomain() => ScheduleSnapshot(
        start: start,
        end: end,
        entries: entries.map((e) => e.toDomain()).toList(),
      );
}
