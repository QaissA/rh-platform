import 'package:alize_mobile/features/team/data/models/my_team_dto.dart';
import 'package:dio/dio.dart';

class TeamRemote {
  TeamRemote(this._dio);

  final Dio _dio;

  Future<MyTeamDto> getMine() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/teams/mine');
    return MyTeamDto.fromJson(response.data!);
  }
}
