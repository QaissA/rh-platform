import '../../../../core/error/result.dart';
import '../entities/session.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<Session>> login({
    required String email,
    required String password,
  });

  Future<Result<User>> me();

  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
