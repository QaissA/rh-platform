import 'package:alize_mobile/features/auth/domain/entities/user.dart';

class CreatedUser {
  const CreatedUser({
    required this.user,
    required this.temporaryPassword,
  });

  final User user;
  final String temporaryPassword;
}
