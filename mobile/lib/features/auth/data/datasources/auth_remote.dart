import 'package:dio/dio.dart';

import '../models/user_dto.dart';

class AuthRemote {
  AuthRemote(this._dio);

  final Dio _dio;

  Future<({String token, UserDto user})> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    return (
      token: data['token'] as String,
      user: UserDto.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  Future<UserDto> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return UserDto.fromJson(response.data!);
  }

  Future<UserDto> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
    return UserDto.fromJson(response.data!);
  }
}
