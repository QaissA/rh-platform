import 'package:alize_mobile/features/team/data/models/schedule_entry_dto.dart';
import 'package:alize_mobile/features/team/domain/entities/new_presence.dart';
import 'package:dio/dio.dart';

class ScheduleRemote {
  ScheduleRemote(this._dio);

  final Dio _dio;

  Future<ScheduleSnapshotDto> getSchedule({
    required String start,
    required String end,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/leave/schedule',
      queryParameters: {'start': start, 'end': end},
    );
    return ScheduleSnapshotDto.fromJson(response.data!);
  }

  Future<List<ScheduleEntryDto>> declarePresence(NewPresence presence) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/leave/presences',
      data: {
        'start_date': presence.startDate,
        'end_date': ?presence.endDate,
        'status': presence.status.wire,
      },
    );
    final entries = response.data?['entries'] as List<dynamic>? ?? const [];
    return entries
        .map(
          (e) => ScheduleEntryDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
