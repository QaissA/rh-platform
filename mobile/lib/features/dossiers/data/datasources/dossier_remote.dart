import 'package:alize_mobile/features/dossiers/data/models/user_dossier_dto.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/update_dossier.dart';
import 'package:dio/dio.dart';

class DossierRemote {
  DossierRemote(this._dio);

  final Dio _dio;

  Future<UserDossierDto> getDossier(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/users/$id');
    return UserDossierDto.fromJson(response.data!);
  }

  Future<UserDossierDto> updateDossier(int id, UpdateDossier payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/users/$id',
      data: _body(payload),
    );
    return UserDossierDto.fromJson(response.data!);
  }

  Future<UserDossierDto> acceptJobTitle(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/users/$id/job-title/accept',
      data: <String, dynamic>{},
    );
    return UserDossierDto.fromJson(response.data!);
  }

  Future<UserDossierDto> rejectJobTitle(int id, {String? comment}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/users/$id/job-title/reject',
      data: {
        'comment': ?comment,
      },
    );
    return UserDossierDto.fromJson(response.data!);
  }

  Future<UserDossierDto> unlockSignature(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/users/$id/signature/unlock',
      data: <String, dynamic>{},
    );
    return UserDossierDto.fromJson(response.data!);
  }

  Map<String, dynamic> _body(UpdateDossier payload) {
    return {
      'first_name': payload.firstName,
      'last_name': payload.lastName,
      'job_title': payload.jobTitle,
      'address_line': payload.addressLine,
      'postal_code': payload.postalCode,
      'city': payload.city,
      'country': payload.country,
      'salary_cents': payload.salaryCents,
      'contract_type': payload.contractType,
      'hired_on': payload.hiredOn,
      'iban': payload.iban,
    };
  }
}
