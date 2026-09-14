import '../../../../core/error/result.dart';
import '../entities/new_project.dart';
import '../entities/project.dart';
import '../entities/update_project.dart';

abstract class ProjectAdminRepository {
  Future<Result<List<Project>>> list({int? businessUnitId});

  Future<Result<Project>> create(NewProject payload);

  Future<Result<Project>> update(int id, UpdateProject payload);

  Future<Result<void>> remove(int id);
}
