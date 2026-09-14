import 'package:alize_mobile/features/admin_business_units/data/models/business_unit_dto.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/new_business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/update_business_unit.dart';
import 'package:dio/dio.dart';

class BusinessUnitAdminRemote {
  BusinessUnitAdminRemote(this._dio);

  final Dio _dio;

  Future<List<BusinessUnitDto>> list() async {
    final response = await _dio.get<List<dynamic>>('/auth/business-units');
    return _list(response.data);
  }

  Future<BusinessUnitDto> create(NewBusinessUnit payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/business-units',
      data: {
        'name': payload.name,
        'manager_id': payload.managerId,
      },
    );
    return BusinessUnitDto.fromJson(response.data!);
  }

  Future<BusinessUnitDto> update(int id, UpdateBusinessUnit payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/business-units/$id',
      data: {
        'name': ?payload.name,
        'manager_id': payload.managerId,
      },
    );
    return BusinessUnitDto.fromJson(response.data!);
  }

  Future<void> remove(int id) async {
    await _dio.delete<void>('/auth/business-units/$id');
  }

  List<BusinessUnitDto> _list(List<dynamic>? data) {
    return (data ?? const [])
        .map(
          (e) =>
              BusinessUnitDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
