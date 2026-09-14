import '../../../../core/error/result.dart';
import '../entities/new_presence.dart';
import '../entities/schedule_entry.dart';
import '../repositories/schedule_repository.dart';

class DeclarePresence {
  DeclarePresence(this._repo);
  final ScheduleRepository _repo;
  Future<Result<List<ScheduleEntry>>> call(NewPresence presence) =>
      _repo.declarePresence(presence);
}
