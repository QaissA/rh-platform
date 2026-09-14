import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/dossiers/data/datasources/dossier_remote.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/update_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/user_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/repositories/dossier_repository.dart';
import 'package:dio/dio.dart';

class DossierRepositoryImpl implements DossierRepository {
  DossierRepositoryImpl({required DossierRemote remote}) : _remote = remote;

  final DossierRemote _remote;

  @override
  Future<Result<UserDossier>> getDossier(int id) => _guard(
        () async => (await _remote.getDossier(id)).toDomain(),
      );

  @override
  Future<Result<UserDossier>> updateDossier(int id, UpdateDossier payload) =>
      _guard(
        () async => (await _remote.updateDossier(id, payload)).toDomain(),
      );

  @override
  Future<Result<UserDossier>> acceptJobTitle(int id) => _guard(
        () async => (await _remote.acceptJobTitle(id)).toDomain(),
      );

  @override
  Future<Result<UserDossier>> rejectJobTitle(int id, {String? comment}) =>
      _guard(
        () async =>
            (await _remote.rejectJobTitle(id, comment: comment)).toDomain(),
      );

  @override
  Future<Result<UserDossier>> unlockSignature(int id) => _guard(
        () async => (await _remote.unlockSignature(id)).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
