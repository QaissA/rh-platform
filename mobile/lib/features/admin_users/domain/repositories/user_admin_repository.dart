import '../../../../core/error/result.dart';
import '../../../auth/domain/entities/user.dart';
import '../entities/created_user.dart';
import '../entities/new_user.dart';
import '../entities/update_user.dart';

abstract class UserAdminRepository {
  Future<Result<List<User>>> list();

  Future<Result<CreatedUser>> create(NewUser payload);

  Future<Result<User>> update(int id, UpdateUser payload);

  Future<Result<void>> remove(int id);

  Future<Result<CreatedUser>> resetPassword(int id);
}
