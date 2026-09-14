import '../../domain/entities/user_profile.dart';

class UserProfileDto {
  const UserProfileDto({
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
    this.addressLine,
    this.postalCode,
    this.city,
    this.country,
    this.signaturePng,
    this.signatureLocked = false,
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
  final String? addressLine;
  final String? postalCode;
  final String? city;
  final String? country;
  final String? signaturePng;
  final bool signatureLocked;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
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
      addressLine: json['address_line'] as String?,
      postalCode: json['postal_code'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      signaturePng: json['signature_png'] as String?,
      signatureLocked: json['signature_locked'] as bool? ?? false,
    );
  }

  UserProfile toDomain() {
    return UserProfile(
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
      addressLine: addressLine,
      postalCode: postalCode,
      city: city,
      country: country,
      signaturePng: signaturePng,
      signatureLocked: signatureLocked,
    );
  }
}
