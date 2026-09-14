import '../../../../core/error/result.dart';
import '../entities/leave_request.dart';
import '../entities/new_leave_request.dart';
import '../repositories/leave_repository.dart';

class CreateLeaveRequest {
  CreateLeaveRequest(this._repo);
  final LeaveRepository _repo;
  Future<Result<LeaveRequest>> call(NewLeaveRequest request) =>
      _repo.create(request);
}
