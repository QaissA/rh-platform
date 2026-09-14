import 'package:alize_mobile/features/admin_business_units/domain/entities/business_unit.dart';
import 'package:alize_mobile/features/team/data/models/team_member_dto.dart';

class BusinessUnitDto {
  const BusinessUnitDto({
    required this.id,
    required this.name,
    this.managerId,
    this.manager,
    this.projectCount = 0,
    this.memberCount = 0,
  });

  final int id;
  final String name;
  final int? managerId;
  final TeamMemberDto? manager;
  final int projectCount;
  final int memberCount;

  factory BusinessUnitDto.fromJson(Map<String, dynamic> json) {
    final rawManager = json['manager'];
    return BusinessUnitDto(
      id: json['id'] as int,
      name: json['name'] as String,
      managerId: json['manager_id'] as int?,
      manager: rawManager is Map
          ? TeamMemberDto.fromJson(Map<String, dynamic>.from(rawManager))
          : null,
      projectCount: json['project_count'] as int? ?? 0,
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  BusinessUnit toDomain() => BusinessUnit(
        id: id,
        name: name,
        managerId: managerId,
        manager: manager?.toDomain(),
        projectCount: projectCount,
        memberCount: memberCount,
      );
}
