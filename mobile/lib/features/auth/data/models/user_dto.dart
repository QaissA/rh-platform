import '../../domain/entities/user.dart';

class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.role,
    this.teamId,
    this.businessUnitId,
    this.projectId,
    this.firstName,
    this.lastName,
    this.jobTitle,
    this.pendingJobTitle,
    this.mustChangePassword = false,
  });

  final int id;
  final String email;
  final String role;
  final int? teamId;
  final int? businessUnitId;
  final int? projectId;
  final String? firstName;
  final String? lastName;
  final String? jobTitle;
  final String? pendingJobTitle;
  final bool mustChangePassword;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      teamId: json['team_id'] as int?,
      businessUnitId: json['business_unit_id'] as int?,
      projectId: json['project_id'] as int?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      jobTitle: json['job_title'] as String?,
      pendingJobTitle: json['pending_job_title'] as String?,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'team_id': teamId,
      'business_unit_id': businessUnitId,
      'project_id': projectId,
      'first_name': firstName,
      'last_name': lastName,
      'job_title': jobTitle,
      'pending_job_title': pendingJobTitle,
      'must_change_password': mustChangePassword,
    };
  }

  User toDomain() {
    return User(
      id: id,
      email: email,
      role: role,
      teamId: teamId,
      businessUnitId: businessUnitId,
      projectId: projectId,
      firstName: firstName,
      lastName: lastName,
      jobTitle: jobTitle,
      pendingJobTitle: pendingJobTitle,
      mustChangePassword: mustChangePassword,
    );
  }
}
