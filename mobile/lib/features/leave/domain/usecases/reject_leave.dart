import '../../../../core/error/result.dart';
import '../entities/leave_request.dart';
import '../repositories/leave_repository.dart';

class RejectLeave {
  RejectLeave(this._repo);
  final LeaveRepository _repo;
  Future<Result<LeaveRequest>> call(int id, {String? comment}) =>
      _repo.reject(id, comment: comment);
}
