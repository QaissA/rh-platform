import 'package:alize_mobile/features/admin_users/domain/entities/created_user.dart';
import 'package:alize_mobile/features/auth/data/models/user_dto.dart';

class CreatedUserDto {
  const CreatedUserDto({
    required this.user,
    required this.temporaryPassword,
  });

  final UserDto user;
  final String temporaryPassword;

  factory CreatedUserDto.fromJson(Map<String, dynamic> json) {
    return CreatedUserDto(
      user: UserDto.fromJson(json),
      temporaryPassword: json['temporary_password'] as String? ?? '',
    );
  }

  CreatedUser toDomain() => CreatedUser(
        user: user.toDomain(),
        temporaryPassword: temporaryPassword,
      );
}
