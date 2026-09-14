import '../../domain/entities/my_team.dart';
import 'team_member_dto.dart';

class MyTeamDto {
  const MyTeamDto({this.team, this.members = const []});

  final TeamRefDto? team;
  final List<TeamMemberDto> members;

  factory MyTeamDto.fromJson(Map<String, dynamic> json) {
    final rawTeam = json['team'];
    return MyTeamDto(
      team: rawTeam is Map
          ? TeamRefDto.fromJson(Map<String, dynamic>.from(rawTeam))
          : null,
      members: (json['members'] as List<dynamic>? ?? const [])
          .map(
            (e) => TeamMemberDto.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  MyTeam toDomain() => MyTeam(
        team: team?.toDomain(),
        members: members.map((e) => e.toDomain()).toList(),
      );
}

class TeamRefDto {
  const TeamRefDto({required this.id, required this.name});

  final int id;
  final String name;

  factory TeamRefDto.fromJson(Map<String, dynamic> json) {
    return TeamRefDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  TeamRef toDomain() => TeamRef(id: id, name: name);
}
