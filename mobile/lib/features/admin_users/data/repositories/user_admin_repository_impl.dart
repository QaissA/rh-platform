import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/admin_users/data/datasources/user_admin_remote.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/created_user.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/new_user.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/update_user.dart';
import 'package:alize_mobile/features/admin_users/domain/repositories/user_admin_repository.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:dio/dio.dart';

class UserAdminRepositoryImpl implements UserAdminRepository {
  UserAdminRepositoryImpl({required UserAdminRemote remote}) : _remote = remote;

  final UserAdminRemote _remote;

  @override
  Future<Result<List<User>>> list() => _guard(
        () async => (await _remote.list()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<CreatedUser>> create(NewUser payload) => _guard(
        () async => (await _remote.create(payload)).toDomain(),
      );

  @override
  Future<Result<User>> update(int id, UpdateUser payload) => _guard(
        () async => (await _remote.update(id, payload)).toDomain(),
      );

  @override
  Future<Result<void>> remove(int id) => _guard(() => _remote.remove(id));

  @override
  Future<Result<CreatedUser>> resetPassword(int id) => _guard(
        () async => (await _remote.resetPassword(id)).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
