class NewUser {
  const NewUser({
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.teamId,
    this.businessUnitId,
    this.projectId,
  });

  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final int? teamId;
  final int? businessUnitId;
  final int? projectId;
}
