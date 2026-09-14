import '../../../../core/error/result.dart';
import '../entities/schedule_entry.dart';
import '../repositories/schedule_repository.dart';

class GetSchedule {
  GetSchedule(this._repo);
  final ScheduleRepository _repo;
  Future<Result<ScheduleSnapshot>> call({
    required String start,
    required String end,
  }) =>
      _repo.getSchedule(start: start, end: end);
}
