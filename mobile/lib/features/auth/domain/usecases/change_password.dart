import '../../../../core/error/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class ChangePassword {
  ChangePassword(this._repo);
  final AuthRepository _repo;
  Future<Result<User>> call(String current, String next) => _repo.changePassword(
        currentPassword: current,
        newPassword: next,
      );
}
