import '../../../../core/error/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

class GetMyRequests {
  GetMyRequests(this._repo);
  final LeaveRepository _repo;
  Future<Result<List<LeaveRequest>>> call() => _repo.getMyRequests();
}
