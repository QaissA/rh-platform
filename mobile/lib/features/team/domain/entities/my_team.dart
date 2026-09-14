import 'team_member.dart';

class TeamRef {
  const TeamRef({required this.id, required this.name});

  final int id;
  final String name;
}

class MyTeam {
  const MyTeam({this.team, this.members = const []});

  final TeamRef? team;
  final List<TeamMember> members;
}
