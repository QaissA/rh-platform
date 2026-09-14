import 'package:alize_mobile/features/team/domain/entities/team_member.dart';

class BusinessUnit {
  const BusinessUnit({
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
  final TeamMember? manager;
  final int projectCount;
  final int memberCount;
}
