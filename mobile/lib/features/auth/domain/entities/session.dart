import 'user.dart';

class Session {
  const Session({required this.token, required this.user});

  final String token;
  final User user;
}
