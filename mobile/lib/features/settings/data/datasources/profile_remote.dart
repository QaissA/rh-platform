import 'package:alize_mobile/features/settings/data/models/user_profile_dto.dart';
import 'package:alize_mobile/features/settings/domain/entities/update_profile.dart';
import 'package:dio/dio.dart';

class ProfileRemote {
  ProfileRemote(this._dio);

  final Dio _dio;

  Future<UserProfileDto> getMine() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/profile');
    return UserProfileDto.fromJson(response.data!);
  }

  Future<UserProfileDto> updateMine(UpdateProfile payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/profile',
      data: _body(payload),
    );
    return UserProfileDto.fromJson(response.data!);
  }

  Map<String, dynamic> _body(UpdateProfile payload) {
    return {
      if (payload.addressLine != null) 'address_line': payload.addressLine,
      if (payload.postalCode != null) 'postal_code': payload.postalCode,
      if (payload.city != null) 'city': payload.city,
      if (payload.country != null) 'country': payload.country,
      if (payload.clearPendingJobTitle)
        'pending_job_title': null
      else if (payload.pendingJobTitle != null)
        'pending_job_title': payload.pendingJobTitle,
      if (payload.signaturePng != null) 'signature_png': payload.signaturePng,
    };
  }
}
