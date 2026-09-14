import '../../../../core/error/result.dart';
import '../entities/update_dossier.dart';
import '../entities/user_dossier.dart';

abstract class DossierRepository {
  Future<Result<UserDossier>> getDossier(int id);

  Future<Result<UserDossier>> updateDossier(int id, UpdateDossier payload);

  Future<Result<UserDossier>> acceptJobTitle(int id);

  Future<Result<UserDossier>> rejectJobTitle(int id, {String? comment});

  Future<Result<UserDossier>> unlockSignature(int id);
}
