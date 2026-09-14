import 'dart:async';
import 'dart:convert';

import 'package:alize_mobile/core/config/app_config.dart';
import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = User(
  id: 1,
  email: 'a@b.com',
  role: 'employee',
  teamId: 2,
  businessUnitId: 3,
  projectId: 4,
  firstName: 'Ada',
  lastName: 'Lovelace',
  jobTitle: 'Engineer',
  mustChangePassword: false,
);

const _session = Session(token: 'jwt', user: _user);

final _userJson = <String, dynamic>{
  'id': 1,
  'email': 'a@b.com',
  'role': 'employee',
  'team_id': 2,
  'business_unit_id': 3,
  'project_id': 4,
  'first_name': 'Ada',
  'last_name': 'Lovelace',
  'job_title': 'Engineer',
  'pending_job_title': null,
  'must_change_password': false,
};

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.changePasswordResult,
  });

  Result<Session>? loginResult;
  Result<User>? changePasswordResult;
  int loginCount = 0;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<Result<Session>> login({
    required String email,
    required String password,
  }) async {
    loginCount++;
    return loginResult ?? const Result.err(Failure.unauthorized());
  }

  @override
  Future<Result<User>> me() async => const Result.err(Failure.unauthorized());

  @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
    return changePasswordResult ?? const Result.err(Failure.unauthorized());
  }
}

Future<AuthState> waitForResolvedAuth(ProviderContainer container) {
  final completer = Completer<AuthState>();
  late final ProviderSubscription<AuthState> sub;
  sub = container.listen<AuthState>(
    authProvider,
    (previous, next) {
      if (next is! AuthUnknown && !completer.isCompleted) {
        completer.complete(next);
        sub.close();
      }
    },
    fireImmediately: true,
  );
  return completer.future;
}

void main() {
  late MemorySessionStore store;
  late FakeAuthRepository repo;

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    store = MemorySessionStore();
    repo = FakeAuthRepository();
  });

  test('empty store yields AuthSignedOut after build', () async {
    final container = createContainer();

    final state = await waitForResolvedAuth(container);

    expect(state, isA<AuthSignedOut>());
    expect(repo.loginCount, 0);
  });

  test('saved token and user hydrate AuthSignedIn without calling login', () async {
    await store.save(token: 'jwt', userJson: jsonEncode(_userJson));
    final container = createContainer();

    final state = await waitForResolvedAuth(container);

    expect(state, isA<AuthSignedIn>());
    final signedIn = state as AuthSignedIn;
    expect(signedIn.session.token, 'jwt');
    expect(signedIn.session.user.email, 'a@b.com');
    expect(signedIn.session.user.firstName, 'Ada');
    expect(signedIn.mustChangePassword, isFalse);
    expect(repo.loginCount, 0);
  });

  test('login ok yields AuthSignedIn', () async {
    repo.loginResult = const Result.ok(_session);
    final container = createContainer();
    await waitForResolvedAuth(container);

    await container.read(authProvider.notifier).login('a@b.com', 'secret');

    final state = container.read(authProvider);
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).session.token, 'jwt');
    expect(state.session.user.email, 'a@b.com');
    expect(repo.loginCount, 1);
  });

  test('logout clears the store and yields AuthSignedOut', () async {
    await store.save(token: 'jwt', userJson: jsonEncode(_userJson));
    final container = createContainer();
    await waitForResolvedAuth(container);

    await container.read(authProvider.notifier).logout();

    expect(container.read(authProvider), isA<AuthSignedOut>());
    expect(await store.readToken(), isNull);
    expect(await store.readUserJson(), isNull);
  });

  test('onUnauthorized signs out and clears the store', () async {
    await store.save(token: 'jwt', userJson: jsonEncode(_userJson));
    final container = createContainer();
    await waitForResolvedAuth(container);

    await container.read(authProvider.notifier).onUnauthorized();

    expect(container.read(authProvider), isA<AuthSignedOut>());
    expect(await store.readToken(), isNull);
    expect(await store.readUserJson(), isNull);
  });

  test('changePassword updates stored user json and signed-in user', () async {
    final pendingJson = Map<String, dynamic>.from(_userJson)
      ..['must_change_password'] = true;
    await store.save(token: 'jwt', userJson: jsonEncode(pendingJson));
    const updated = User(
      id: 1,
      email: 'a@b.com',
      role: 'employee',
      teamId: 2,
      businessUnitId: 3,
      projectId: 4,
      firstName: 'Ada',
      lastName: 'Lovelace',
      jobTitle: 'Engineer',
    );
    repo.changePasswordResult = const Result.ok(updated);
    final container = createContainer();
    final before = await waitForResolvedAuth(container);
    expect((before as AuthSignedIn).mustChangePassword, isTrue);

    await container.read(authProvider.notifier).changePassword(
          currentPassword: 'old',
          newPassword: 'new-secret',
        );

    final state = container.read(authProvider);
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).mustChangePassword, isFalse);
    expect(state.session.token, 'jwt');
    final stored =
        jsonDecode(await store.readUserJson() as String) as Map<String, dynamic>;
    expect(stored['must_change_password'], isFalse);
    expect(stored['email'], 'a@b.com');
    expect(await store.readToken(), 'jwt');
  });

  test('login with mustChangePassword keeps password in memory only', () async {
    const pending = User(
      id: 1,
      email: 'a@b.com',
      role: 'employee',
      firstName: 'Ada',
      lastName: 'Lovelace',
      mustChangePassword: true,
    );
    repo.loginResult = const Result.ok(Session(token: 'jwt', user: pending));
    final container = createContainer();
    await waitForResolvedAuth(container);

    await container.read(authProvider.notifier).login('a@b.com', 'TempPass1');

    final notifier = container.read(authProvider.notifier);
    expect(notifier.hasTempPassword, isTrue);
    expect(await store.readUserJson(), isNull);
    expect(await store.readToken(), isNull);
  });

  test('changePasswordForced uses in-memory temp then clears it', () async {
    const pending = User(
      id: 1,
      email: 'a@b.com',
      role: 'employee',
      firstName: 'Ada',
      lastName: 'Lovelace',
      mustChangePassword: true,
    );
    const updated = User(
      id: 1,
      email: 'a@b.com',
      role: 'employee',
      firstName: 'Ada',
      lastName: 'Lovelace',
    );
    repo.loginResult = const Result.ok(Session(token: 'jwt', user: pending));
    repo.changePasswordResult = const Result.ok(updated);
    final container = createContainer();
    await waitForResolvedAuth(container);

    final notifier = container.read(authProvider.notifier);
    await notifier.login('a@b.com', 'TempPass1');
    await notifier.changePasswordForced('NewSecret1');

    expect(repo.lastCurrentPassword, 'TempPass1');
    expect(repo.lastNewPassword, 'NewSecret1');
    expect(notifier.hasTempPassword, isFalse);
    expect(
      (container.read(authProvider) as AuthSignedIn).mustChangePassword,
      isFalse,
    );
  });

  test('auth and dio providers can be read together without a cycle', () async {
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        appConfigProvider.overrideWithValue(
          const AppConfig(apiBaseUrl: 'http://example.test'),
        ),
      ],
    );
    addTearDown(container.dispose);

    await waitForResolvedAuth(container);
    expect(container.read(dioProvider).options.baseUrl, 'http://example.test');
    expect(container.read(authRepositoryProvider), isA<AuthRepositoryImpl>());
  });
}
