import '../../../../core/error/result.dart';
import '../entities/leave_balance.dart';
import '../repositories/leave_repository.dart';

class GetBalance {
  GetBalance(this._repo);
  final LeaveRepository _repo;
  Future<Result<LeaveBalance>> call() => _repo.getBalance();
}
