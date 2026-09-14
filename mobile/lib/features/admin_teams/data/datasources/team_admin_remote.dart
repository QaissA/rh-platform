import 'package:alize_mobile/features/admin_teams/data/models/team_admin_dto.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/new_team.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/update_team.dart';
import 'package:dio/dio.dart';

class TeamAdminRemote {
  TeamAdminRemote(this._dio);

  final Dio _dio;

  Future<List<TeamSummaryDto>> list() async {
    final response = await _dio.get<List<dynamic>>('/auth/teams');
    return (response.data ?? const [])
        .map(
          (e) => TeamSummaryDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<TeamDetailDto> get(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/teams/$id');
    return TeamDetailDto.fromJson(response.data!);
  }

  Future<TeamSummaryDto> create(NewTeam payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/teams',
      data: {
        'name': payload.name,
        'project_id': payload.projectId,
      },
    );
    return TeamSummaryDto.fromJson(response.data!);
  }

  Future<TeamSummaryDto> update(int id, UpdateTeam payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/teams/$id',
      data: {
        'name': ?payload.name,
        'project_id': payload.projectId,
      },
    );
    return TeamSummaryDto.fromJson(response.data!);
  }

  Future<void> remove(int id) async {
    await _dio.delete<void>('/auth/teams/$id');
  }
}
