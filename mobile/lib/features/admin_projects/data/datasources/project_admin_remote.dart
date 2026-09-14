import 'package:alize_mobile/features/admin_projects/data/models/project_dto.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/new_project.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/update_project.dart';
import 'package:dio/dio.dart';

class ProjectAdminRemote {
  ProjectAdminRemote(this._dio);

  final Dio _dio;

  Future<List<ProjectDto>> list({int? businessUnitId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/auth/projects',
      queryParameters: {
        'business_unit_id': ?businessUnitId,
      },
    );
    return _list(response.data);
  }

  Future<ProjectDto> create(NewProject payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/projects',
      data: {
        'name': payload.name,
        'business_unit_id': payload.businessUnitId,
        'lead_id': payload.leadId,
      },
    );
    return ProjectDto.fromJson(response.data!);
  }

  Future<ProjectDto> update(int id, UpdateProject payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/projects/$id',
      data: {
        'name': ?payload.name,
        'business_unit_id': ?payload.businessUnitId,
        'lead_id': payload.leadId,
      },
    );
    return ProjectDto.fromJson(response.data!);
  }

  Future<void> remove(int id) async {
    await _dio.delete<void>('/auth/projects/$id');
  }

  List<ProjectDto> _list(List<dynamic>? data) {
    return (data ?? const [])
        .map(
          (e) => ProjectDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
