import '../../../../core/error/result.dart';
import '../entities/leave_balance.dart';
import '../entities/leave_request.dart';
import '../entities/leave_status.dart';
import '../entities/new_leave_request.dart';

abstract class LeaveRepository {
  Future<Result<LeaveBalance>> getBalance();

  Future<Result<List<LeaveRequest>>> getMyRequests();

  Future<Result<LeaveRequest>> create(NewLeaveRequest request);

  Future<Result<List<LeaveRequest>>> getTeamRequests({
    List<LeaveStatus>? status,
  });

  Future<Result<LeaveRequest>> approve(int id);

  Future<Result<LeaveRequest>> reject(int id, {String? comment});
}
