class UpdateProfile {
  const UpdateProfile({
    this.addressLine,
    this.postalCode,
    this.city,
    this.country,
    this.pendingJobTitle,
    this.clearPendingJobTitle = false,
    this.signaturePng,
  });

  final String? addressLine;
  final String? postalCode;
  final String? city;
  final String? country;
  final String? pendingJobTitle;
  final bool clearPendingJobTitle;
  final String? signaturePng;
}
