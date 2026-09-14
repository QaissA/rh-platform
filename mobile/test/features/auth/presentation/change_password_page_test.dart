import 'dart:async';
import 'dart:convert';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:alize_mobile/features/auth/presentation/pages/change_password_page.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _pendingUser = User(
  id: 1,
  email: 'a@b.com',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
  mustChangePassword: true,
);

const _updatedUser = User(
  id: 1,
  email: 'a@b.com',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

const _pendingSession = Session(token: 'jwt', user: _pendingUser);

final _pendingUserJson = <String, dynamic>{
  'id': 1,
  'email': 'a@b.com',
  'role': 'employee',
  'first_name': 'Ada',
  'last_name': 'Lovelace',
  'must_change_password': true,
};

const _fr = {
  'brand': 'Alizé',
  'lang': {'label': 'Langue'},
  'login': {
    'offline':
        'Impossible de joindre le serveur. La passerelle est-elle démarrée ?',
  },
  'password': {
    'headline': 'Sécurisons votre compte.',
    'pitch':
        'Votre mot de passe temporaire doit être remplacé avant d\'accéder à votre espace.',
    'ruleLength': 'Au moins {{n}} caractères',
    'ruleDifferent': 'Différent du mot de passe temporaire',
    'ruleSecret': 'Gardez-le confidentiel',
    'title': 'Nouveau mot de passe 🔒',
    'subtitle': 'Choisissez un mot de passe personnel pour continuer.',
    'temp': 'Mot de passe temporaire',
    'new': 'Nouveau mot de passe',
    'confirm': 'Confirmer le mot de passe',
    'tooShort': '8 caractères minimum.',
    'sameAsTemp': 'Doit être différent du mot de passe temporaire.',
    'mismatch': 'Les mots de passe ne correspondent pas.',
    'submit': 'Mettre à jour le mot de passe',
    'submitting': 'Mise à jour…',
    'fail': 'Échec de la mise à jour du mot de passe.',
  },
};

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.loginResult,
    this.changePasswordResult,
  });

  Result<Session>? loginResult;
  Result<User>? changePasswordResult;
  String? lastCurrentPassword;
  String? lastNewPassword;

  @override
  Future<Result<Session>> login({
    required String email,
    required String password,
  }) async {
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
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

void main() {
  late I18n i18n;
  late ThemeData theme;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = I18n(dicts: {'fr': Map<String, dynamic>.from(_fr)});
    theme = AlizeTheme.light();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required FakeAuthRepository repo,
    MemorySessionStore? store,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(store ?? MemorySessionStore()),
          authRepositoryProvider.overrideWithValue(repo),
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
        ],
        child: MaterialApp(
          theme: theme,
          home: const ChangePasswordPage(),
        ),
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChangePasswordPage)),
    );
    await waitForResolvedAuth(container);
    await tester.pump();
  }

  AuthState readAuth(WidgetTester tester) {
    return ProviderScope.containerOf(
      tester.element(find.byType(ChangePasswordPage)),
    ).read(authProvider);
  }

  Future<void> captureTempPassword(
    WidgetTester tester, {
    String password = 'TempPass1',
  }) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChangePasswordPage)),
    );
    await container.read(authProvider.notifier).login('a@b.com', password);
    await tester.pump();
  }

  Finder submitButton() =>
      find.widgetWithText(FilledButton, i18n.t('password.submit'));

  testWidgets(
    'submit valid password on mustChangePassword session clears the flag',
    (tester) async {
      final store = MemorySessionStore();
      await store.save(
        token: 'jwt',
        userJson: jsonEncode(_pendingUserJson),
      );
      final repo = FakeAuthRepository(
        loginResult: const Result.ok(_pendingSession),
        changePasswordResult: const Result.ok(_updatedUser),
      );
      await pumpPage(tester, repo: repo, store: store);
      expect(
        (readAuth(tester) as AuthSignedIn).mustChangePassword,
        isTrue,
      );

      await captureTempPassword(tester);
      expect(find.byKey(ChangePasswordPage.currentPasswordFieldKey), findsNothing);

      await tester.enterText(
        find.byKey(ChangePasswordPage.newPasswordFieldKey),
        'NewSecret1',
      );
      await tester.enterText(
        find.byKey(ChangePasswordPage.confirmPasswordFieldKey),
        'NewSecret1',
      );
      await tester.pump();

      await tester.tap(submitButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(readAuth(tester), isA<AuthSignedIn>());
      expect((readAuth(tester) as AuthSignedIn).mustChangePassword, isFalse);
      expect(repo.lastCurrentPassword, 'TempPass1');
      expect(repo.lastNewPassword, 'NewSecret1');
    },
  );

  testWidgets('too-short password disables submit', (tester) async {
    final store = MemorySessionStore();
    await store.save(
      token: 'jwt',
      userJson: jsonEncode(_pendingUserJson),
    );
    final repo = FakeAuthRepository(
      loginResult: const Result.ok(_pendingSession),
    );
    await pumpPage(tester, repo: repo, store: store);
    await captureTempPassword(tester);

    await tester.enterText(
      find.byKey(ChangePasswordPage.newPasswordFieldKey),
      'short',
    );
    await tester.enterText(
      find.byKey(ChangePasswordPage.confirmPasswordFieldKey),
      'short',
    );
    await tester.pump();

    expect(tester.widget<FilledButton>(submitButton()).onPressed, isNull);
    expect(find.text(i18n.t('password.tooShort')), findsOneWidget);
  });

  testWidgets('shows current password field when temp was not captured',
      (tester) async {
    final store = MemorySessionStore();
    await store.save(
      token: 'jwt',
      userJson: jsonEncode(_pendingUserJson),
    );
    await pumpPage(tester, repo: FakeAuthRepository(), store: store);

    expect(
      find.byKey(ChangePasswordPage.currentPasswordFieldKey),
      findsOneWidget,
    );
  });
}
