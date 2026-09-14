import 'package:alize_mobile/features/admin_projects/domain/entities/org_ref.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/project.dart';
import 'package:alize_mobile/features/team/data/models/team_member_dto.dart';

class ProjectDto {
  const ProjectDto({
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
  final TeamMemberDto? lead;
  final int memberCount;

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    final rawLead = json['lead'];
    return ProjectDto(
      id: json['id'] as int,
      name: json['name'] as String,
      businessUnitId: json['business_unit_id'] as int,
      businessUnit: _ref(json['business_unit']),
      leadId: json['lead_id'] as int?,
      lead: rawLead is Map
          ? TeamMemberDto.fromJson(Map<String, dynamic>.from(rawLead))
          : null,
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  Project toDomain() => Project(
        id: id,
        name: name,
        businessUnitId: businessUnitId,
        businessUnit: businessUnit,
        leadId: leadId,
        lead: lead?.toDomain(),
        memberCount: memberCount,
      );
}

OrgRef? _ref(dynamic raw) {
  if (raw is! Map) return null;
  final json = Map<String, dynamic>.from(raw);
  final id = json['id'];
  final name = json['name'];
  if (id is! int || name is! String) return null;
  return OrgRef(id: id, name: name);
}
