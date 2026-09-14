import 'package:alize_mobile/features/admin_users/data/models/created_user_dto.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/new_user.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/update_user.dart';
import 'package:alize_mobile/features/auth/data/models/user_dto.dart';
import 'package:dio/dio.dart';

class UserAdminRemote {
  UserAdminRemote(this._dio);

  final Dio _dio;

  Future<List<UserDto>> list() async {
    final response = await _dio.get<List<dynamic>>('/auth/users');
    return (response.data ?? const [])
        .map(
          (e) => UserDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<CreatedUserDto> create(NewUser payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/users',
      data: {
        'email': payload.email,
        'first_name': payload.firstName,
        'last_name': payload.lastName,
        'role': payload.role,
        'team_id': payload.teamId,
        'business_unit_id': payload.businessUnitId,
        'project_id': payload.projectId,
      },
    );
    return CreatedUserDto.fromJson(response.data!);
  }

  Future<UserDto> update(int id, UpdateUser payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/users/$id',
      data: {
        'role': ?payload.role,
        'first_name': ?payload.firstName,
        'last_name': ?payload.lastName,
        'team_id': payload.teamId,
        'business_unit_id': payload.businessUnitId,
        'project_id': payload.projectId,
      },
    );
    return UserDto.fromJson(response.data!);
  }

  Future<void> remove(int id) async {
    await _dio.delete<void>('/auth/users/$id');
  }

  Future<CreatedUserDto> resetPassword(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/users/$id/reset-password',
      data: <String, dynamic>{},
    );
    return CreatedUserDto.fromJson(response.data!);
  }
}
