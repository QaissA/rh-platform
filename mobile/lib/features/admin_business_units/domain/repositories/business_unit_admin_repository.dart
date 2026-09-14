import '../../../../core/error/result.dart';
import '../entities/business_unit.dart';
import '../entities/new_business_unit.dart';
import '../entities/update_business_unit.dart';

abstract class BusinessUnitAdminRepository {
  Future<Result<List<BusinessUnit>>> list();

  Future<Result<BusinessUnit>> create(NewBusinessUnit payload);

  Future<Result<BusinessUnit>> update(int id, UpdateBusinessUnit payload);

  Future<Result<void>> remove(int id);
}
