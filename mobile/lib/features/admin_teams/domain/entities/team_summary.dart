import 'package:alize_mobile/features/admin_projects/domain/entities/org_ref.dart';

class TeamSummary {
  const TeamSummary({
    required this.id,
    required this.name,
    this.projectId,
    this.project,
    this.businessUnit,
    this.memberCount = 0,
  });

  final int id;
  final String name;
  final int? projectId;
  final OrgRef? project;
  final OrgRef? businessUnit;
  final int memberCount;
}
