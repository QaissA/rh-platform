import '../../../../core/error/result.dart';
import '../entities/update_profile.dart';
import '../entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Result<UserProfile>> getMine();

  Future<Result<UserProfile>> updateMine(UpdateProfile payload);
}
