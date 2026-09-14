class UpdateDossier {
  const UpdateDossier({
    this.firstName,
    this.lastName,
    this.jobTitle,
    this.addressLine,
    this.postalCode,
    this.city,
    this.country,
    this.salaryCents,
    this.contractType,
    this.hiredOn,
    this.iban,
  });

  final String? firstName;
  final String? lastName;
  final String? jobTitle;
  final String? addressLine;
  final String? postalCode;
  final String? city;
  final String? country;
  final int? salaryCents;
  final String? contractType;
  final String? hiredOn;
  final String? iban;
}
