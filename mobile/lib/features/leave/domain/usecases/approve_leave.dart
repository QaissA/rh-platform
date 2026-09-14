import '../../../../core/error/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

class ApproveLeave {
  ApproveLeave(this._repo);
  final LeaveRepository _repo;
  Future<Result<LeaveRequest>> call(int id) => _repo.approve(id);
}
