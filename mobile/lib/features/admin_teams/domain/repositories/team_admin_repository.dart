import '../../../../core/error/result.dart';
import '../entities/new_team.dart';
import '../entities/team_detail.dart';
import '../entities/team_summary.dart';
import '../entities/update_team.dart';

abstract class TeamAdminRepository {
  Future<Result<List<TeamSummary>>> list();

  Future<Result<TeamDetail>> get(int id);

  Future<Result<TeamSummary>> create(NewTeam payload);

  Future<Result<TeamSummary>> update(int id, UpdateTeam payload);

  Future<Result<void>> remove(int id);
}
