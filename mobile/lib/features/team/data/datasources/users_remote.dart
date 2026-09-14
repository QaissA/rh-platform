import 'package:alize_mobile/features/auth/data/models/user_dto.dart';
import 'package:dio/dio.dart';

class UsersRemote {
  UsersRemote(this._dio);

  final Dio _dio;

  Future<List<UserDto>> list() async {
    final response = await _dio.get<List<dynamic>>('/auth/users');
    return (response.data ?? const [])
        .map(
          (e) => UserDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
