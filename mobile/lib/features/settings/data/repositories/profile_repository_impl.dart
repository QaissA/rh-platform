import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/settings/data/datasources/profile_remote.dart';
import 'package:alize_mobile/features/settings/domain/entities/update_profile.dart';
import 'package:alize_mobile/features/settings/domain/entities/user_profile.dart';
import 'package:alize_mobile/features/settings/domain/repositories/profile_repository.dart';
import 'package:dio/dio.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required ProfileRemote remote}) : _remote = remote;

  final ProfileRemote _remote;

  @override
  Future<Result<UserProfile>> getMine() => _guard(
        () async => (await _remote.getMine()).toDomain(),
      );

  @override
  Future<Result<UserProfile>> updateMine(UpdateProfile payload) => _guard(
        () async => (await _remote.updateMine(payload)).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
