import '../../../../core/error/result.dart';
import '../entities/session.dart';
import '../repositories/auth_repository.dart';

class Login {
  Login(this._repo);
  final AuthRepository _repo;
  Future<Result<Session>> call(String email, String password) =>
      _repo.login(email: email, password: password);
}
