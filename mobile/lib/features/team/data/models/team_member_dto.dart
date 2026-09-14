import '../../domain/entities/team_member.dart';

class TeamMemberDto {
  const TeamMemberDto({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.jobTitle,
  });

  final int id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? jobTitle;

  factory TeamMemberDto.fromJson(Map<String, dynamic> json) {
    return TeamMemberDto(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      jobTitle: json['job_title'] as String?,
    );
  }

  TeamMember toDomain() => TeamMember(
        id: id,
        email: email,
        role: role,
        firstName: firstName,
        lastName: lastName,
        jobTitle: jobTitle,
      );
}
