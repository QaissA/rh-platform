import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/admin_teams/data/datasources/team_admin_remote.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/new_team.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_detail.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_summary.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/update_team.dart';
import 'package:alize_mobile/features/admin_teams/domain/repositories/team_admin_repository.dart';
import 'package:dio/dio.dart';

class TeamAdminRepositoryImpl implements TeamAdminRepository {
  TeamAdminRepositoryImpl({required TeamAdminRemote remote}) : _remote = remote;

  final TeamAdminRemote _remote;

  @override
  Future<Result<List<TeamSummary>>> list() => _guard(
        () async => (await _remote.list()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<TeamDetail>> get(int id) => _guard(
        () async => (await _remote.get(id)).toDetail(),
      );

  @override
  Future<Result<TeamSummary>> create(NewTeam payload) => _guard(
        () async => (await _remote.create(payload)).toDomain(),
      );

  @override
  Future<Result<TeamSummary>> update(int id, UpdateTeam payload) => _guard(
        () async => (await _remote.update(id, payload)).toDomain(),
      );

  @override
  Future<Result<void>> remove(int id) => _guard(() => _remote.remove(id));

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
