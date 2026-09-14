import 'package:alize_mobile/features/admin_projects/domain/entities/org_ref.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';

class Project {
  const Project({
    required this.id,
    required this.name,
    required this.businessUnitId,
    this.businessUnit,
    this.leadId,
    this.lead,
    this.memberCount = 0,
  });

  final int id;
  final String name;
  final int businessUnitId;
  final OrgRef? businessUnit;
  final int? leadId;
  final TeamMember? lead;
  final int memberCount;
}
