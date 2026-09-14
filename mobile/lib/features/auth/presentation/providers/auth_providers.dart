import 'dart:async';
import 'dart:convert';

import 'package:alize_mobile/core/config/app_config.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/dio_client.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/features/auth/data/datasources/auth_remote.dart';
import 'package:alize_mobile/features/auth/data/models/user_dto.dart';
import 'package:alize_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

export 'auth_state.dart';

final sessionStoreProvider = Provider<SessionStore>(
  (_) => SecureSessionStore(const FlutterSecureStorage()),
);

final appConfigProvider = Provider<AppConfig>((_) => AppConfig.current);

final unauthorizedHandlerProvider = Provider<void Function()>((ref) {
  return () => ref.read(authProvider.notifier).onUnauthorized();
});

final dioProvider = Provider<Dio>((ref) {
  return createDio(
    config: ref.watch(appConfigProvider),
    interceptor: AuthInterceptor(
      token: () {
        final s = ref.read(authProvider);
        if (s is AuthSignedIn) return s.session.token;
        return null;
      },
      onUnauthorized: () => ref.read(unauthorizedHandlerProvider).call(),
    ),
  );
});

final authRemoteProvider = Provider<AuthRemote>(
  (ref) => AuthRemote(ref.watch(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteProvider),
    sessionStore: ref.watch(sessionStoreProvider),
  ),
);

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  bool _disposed = false;
  String? _tempPassword;

  bool get hasTempPassword =>
      _tempPassword != null && _tempPassword!.isNotEmpty;

  @override
  AuthState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_hydrate());
    return const AuthUnknown();
  }

  Future<void> _hydrate() async {
    final store = ref.read(sessionStoreProvider);
    final token = await store.readToken();
    final userJson = await store.readUserJson();
    if (_disposed) return;
    if (state is AuthSignedIn) return;

    if (token == null || token.isEmpty || userJson == null || userJson.isEmpty) {
      state = const AuthSignedOut();
      return;
    }

    try {
      final user = UserDto.fromJson(
        Map<String, dynamic>.from(jsonDecode(userJson) as Map),
      ).toDomain();
      state = AuthSignedIn(Session(token: token, user: user));
    } catch (_) {
      state = const AuthSignedOut();
    }
  }

  Future<Result<Session>> login(String email, String password) async {
    final result = await ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
        );
    if (_disposed) return result;
    final session = result.data;
    if (result.isOk && session != null) {
      _tempPassword = session.user.mustChangePassword ? password : null;
      state = AuthSignedIn(session);
    }
    return result;
  }

  Future<void> logout() async {
    _tempPassword = null;
    await ref.read(sessionStoreProvider).clear();
    if (_disposed) return;
    state = const AuthSignedOut();
  }

  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await ref.read(authRepositoryProvider).changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
    final user = result.data;
    if (!result.isOk || user == null) return result;

    final store = ref.read(sessionStoreProvider);
    final current = state;
    final token = current is AuthSignedIn
        ? current.session.token
        : await store.readToken();
    if (token == null) return result;

    await store.save(
      token: token,
      userJson: jsonEncode(_dtoFromUser(user).toJson()),
    );
    _tempPassword = null;
    if (_disposed) return result;
    state = AuthSignedIn(Session(token: token, user: user));
    return result;
  }

  Future<Result<User>> changePasswordForced(String newPassword) {
    return changePassword(
      currentPassword: _tempPassword ?? '',
      newPassword: newPassword,
    );
  }

  Future<void> onUnauthorized() => logout();
}

UserDto _dtoFromUser(User user) {
  return UserDto(
    id: user.id,
    email: user.email,
    role: user.role,
    teamId: user.teamId,
    businessUnitId: user.businessUnitId,
    projectId: user.projectId,
    firstName: user.firstName,
    lastName: user.lastName,
    jobTitle: user.jobTitle,
    pendingJobTitle: user.pendingJobTitle,
    mustChangePassword: user.mustChangePassword,
  );
}
