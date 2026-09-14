import '../../../../core/error/result.dart';
import '../entities/leave_request.dart';
import '../entities/leave_status.dart';
import '../repositories/leave_repository.dart';

class GetTeamRequests {
  GetTeamRequests(this._repo);
  final LeaveRepository _repo;
  Future<Result<List<LeaveRequest>>> call([List<LeaveStatus>? status]) =>
      _repo.getTeamRequests(status: status);
}
