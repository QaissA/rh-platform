class User {
  const User({
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
}
