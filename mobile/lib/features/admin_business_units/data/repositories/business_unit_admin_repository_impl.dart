import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/admin_business_units/data/datasources/business_unit_admin_remote.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/new_business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/update_business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/domain/repositories/business_unit_admin_repository.dart';
import 'package:dio/dio.dart';

class BusinessUnitAdminRepositoryImpl implements BusinessUnitAdminRepository {
  BusinessUnitAdminRepositoryImpl({required BusinessUnitAdminRemote remote})
      : _remote = remote;

  final BusinessUnitAdminRemote _remote;

  @override
  Future<Result<List<BusinessUnit>>> list() => _guard(
        () async => (await _remote.list()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<BusinessUnit>> create(NewBusinessUnit payload) => _guard(
        () async => (await _remote.create(payload)).toDomain(),
      );

  @override
  Future<Result<BusinessUnit>> update(int id, UpdateBusinessUnit payload) =>
      _guard(
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
