import 'package:alize_mobile/features/team/domain/entities/team_member.dart';

import 'team_summary.dart';

class TeamDetail extends TeamSummary {
  const TeamDetail({
    required super.id,
    required super.name,
    super.projectId,
    super.project,
    super.businessUnit,
    super.memberCount = 0,
    this.members = const [],
  });

  final List<TeamMember> members;
}
