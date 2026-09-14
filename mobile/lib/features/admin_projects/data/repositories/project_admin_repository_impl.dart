import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/admin_projects/data/datasources/project_admin_remote.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/new_project.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/project.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/update_project.dart';
import 'package:alize_mobile/features/admin_projects/domain/repositories/project_admin_repository.dart';
import 'package:dio/dio.dart';

class ProjectAdminRepositoryImpl implements ProjectAdminRepository {
  ProjectAdminRepositoryImpl({required ProjectAdminRemote remote})
      : _remote = remote;

  final ProjectAdminRemote _remote;

  @override
  Future<Result<List<Project>>> list({int? businessUnitId}) => _guard(
        () async => (await _remote.list(businessUnitId: businessUnitId))
            .map((e) => e.toDomain())
            .toList(),
      );

  @override
  Future<Result<Project>> create(NewProject payload) => _guard(
        () async => (await _remote.create(payload)).toDomain(),
      );

  @override
  Future<Result<Project>> update(int id, UpdateProject payload) => _guard(
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
