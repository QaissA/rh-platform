import '../../../../core/error/result.dart';
import '../entities/my_team.dart';
import '../repositories/team_repository.dart';

class GetMyTeam {
  GetMyTeam(this._repo);
  final TeamRepository _repo;
  Future<Result<MyTeam>> call() => _repo.getMine();
}
