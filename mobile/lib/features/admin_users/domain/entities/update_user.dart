class UpdateUser {
  const UpdateUser({
    this.role,
    this.firstName,
    this.lastName,
    this.teamId,
    this.businessUnitId,
    this.projectId,
  });

  final String? role;
  final String? firstName;
  final String? lastName;
  final int? teamId;
  final int? businessUnitId;
  final int? projectId;
}
