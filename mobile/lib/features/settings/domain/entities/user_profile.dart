class UserProfile {
  const UserProfile({
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

  bool get canDrawSignature =>
      signaturePng == null || signaturePng!.isEmpty || !signatureLocked;
}
