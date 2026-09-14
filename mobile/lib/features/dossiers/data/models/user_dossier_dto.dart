import '../../../settings/data/models/user_profile_dto.dart';
import '../../domain/entities/user_dossier.dart';

class UserDossierDto {
  const UserDossierDto({
    required this.profile,
    this.salaryCents,
    this.contractType,
    this.hiredOn,
    this.iban,
  });

  final UserProfileDto profile;
  final int? salaryCents;
  final String? contractType;
  final String? hiredOn;
  final String? iban;

  factory UserDossierDto.fromJson(Map<String, dynamic> json) {
    return UserDossierDto(
      profile: UserProfileDto.fromJson(json),
      salaryCents: _asInt(json['salary_cents']),
      contractType: json['contract_type'] as String?,
      hiredOn: _asDate(json['hired_on']),
      iban: json['iban'] as String?,
    );
  }

  UserDossier toDomain() {
    return UserDossier(
      profile: profile.toDomain(),
      salaryCents: salaryCents,
      contractType: contractType,
      hiredOn: hiredOn,
      iban: iban,
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return null;
}

String? _asDate(dynamic value) {
  if (value is String && value.isNotEmpty) return value.split('T').first;
  return null;
}
