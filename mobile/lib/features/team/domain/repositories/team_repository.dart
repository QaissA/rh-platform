import '../../../../core/error/result.dart';
import '../entities/my_team.dart';

abstract class TeamRepository {
  Future<Result<MyTeam>> getMine();
}
