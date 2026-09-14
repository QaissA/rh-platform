import 'package:alize_mobile/features/admin_projects/domain/entities/org_ref.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_detail.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_summary.dart';
import 'package:alize_mobile/features/team/data/models/team_member_dto.dart';

class TeamSummaryDto {
  const TeamSummaryDto({
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

  factory TeamSummaryDto.fromJson(Map<String, dynamic> json) {
    return TeamSummaryDto(
      id: json['id'] as int,
      name: json['name'] as String,
      projectId: json['project_id'] as int?,
      project: _ref(json['project']),
      businessUnit: _ref(json['business_unit']),
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  TeamSummary toDomain() => TeamSummary(
        id: id,
        name: name,
        projectId: projectId,
        project: project,
        businessUnit: businessUnit,
        memberCount: memberCount,
      );
}

class TeamDetailDto extends TeamSummaryDto {
  const TeamDetailDto({
    required super.id,
    required super.name,
    super.projectId,
    super.project,
    super.businessUnit,
    super.memberCount = 0,
    this.members = const [],
  });

  final List<TeamMemberDto> members;

  factory TeamDetailDto.fromJson(Map<String, dynamic> json) {
    final summary = TeamSummaryDto.fromJson(json);
    final rawMembers = json['members'];
    return TeamDetailDto(
      id: summary.id,
      name: summary.name,
      projectId: summary.projectId,
      project: summary.project,
      businessUnit: summary.businessUnit,
      memberCount: summary.memberCount,
      members: rawMembers is List
          ? rawMembers
              .whereType<Map>()
              .map(
                (e) => TeamMemberDto.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const [],
    );
  }

  TeamDetail toDetail() => TeamDetail(
        id: id,
        name: name,
        projectId: projectId,
        project: project,
        businessUnit: businessUnit,
        memberCount: memberCount,
        members: members.map((e) => e.toDomain()).toList(),
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
