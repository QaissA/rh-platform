import '../../../settings/domain/entities/user_profile.dart';

const contractTypes = ['cdi', 'cdd', 'stage', 'alternance', 'other'];

class UserDossier {
  const UserDossier({
    required this.profile,
    this.salaryCents,
    this.contractType,
    this.hiredOn,
    this.iban,
  });

  final UserProfile profile;
  final int? salaryCents;
  final String? contractType;
  final String? hiredOn;
  final String? iban;

  int get id => profile.id;

  /// Display euros: cents / 100. Inverse of [salaryCentsFromEuros].
  double? get salaryEuros =>
      salaryCents == null ? null : salaryCents! / 100;
}

int? salaryCentsFromEuros(num? euros) {
  if (euros == null) return null;
  return (euros.toDouble() * 100).round();
}
