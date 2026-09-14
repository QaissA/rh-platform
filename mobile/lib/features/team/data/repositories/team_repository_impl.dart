import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/team/data/datasources/team_remote.dart';
import 'package:alize_mobile/features/team/domain/entities/my_team.dart';
import 'package:alize_mobile/features/team/domain/repositories/team_repository.dart';
import 'package:dio/dio.dart';

class TeamRepositoryImpl implements TeamRepository {
  TeamRepositoryImpl({required TeamRemote remote}) : _remote = remote;

  final TeamRemote _remote;

  @override
  Future<Result<MyTeam>> getMine() => _guard(
        () async => (await _remote.getMine()).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
