class TeamMember {
  const TeamMember({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.jobTitle,
    this.pendingJobTitle,
  });

  final int id;
  final String email;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? jobTitle;
  final String? pendingJobTitle;
}
