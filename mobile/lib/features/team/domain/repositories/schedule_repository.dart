import '../../../../core/error/result.dart';
import '../entities/new_presence.dart';
import '../entities/schedule_entry.dart';

abstract class ScheduleRepository {
  Future<Result<ScheduleSnapshot>> getSchedule({
    required String start,
    required String end,
  });

  Future<Result<List<ScheduleEntry>>> declarePresence(NewPresence presence);
}
