import 'package:alize_mobile/features/auth/domain/entities/session.dart';

sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.session);

  final Session session;

  bool get mustChangePassword => session.user.mustChangePassword;
}
