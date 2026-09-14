import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:alize_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _user = User(
  id: 1,
  email: 'a@b.com',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

const _session = Session(token: 'jwt', user: _user);

const _frLogin = {
  'brand': 'Alizé',
  'lang': {'label': 'Langue'},
  'common': {
    'role': {'admin': 'Administrateur·rice'},
  },
  'login': {
    'headline': 'La respiration RH de votre équipe.',
    'pitch': 'Congés, présence et démarches administratives.',
    'statBalance': 'jours de solde',
    'statTeammates': 'coéquipiers',
    'statPending': 'demandes en cours',
    'welcome': 'Bon retour 👋',
    'subtitle': 'Connectez-vous à votre espace Alizé.',
    'email': 'Adresse e-mail',
    'password': 'Mot de passe',
    'submit': 'Se connecter',
    'submitting': 'Connexion…',
    'demos': 'Comptes de démo',
    'demoEmployee': 'Employé',
    'demoManager': 'Manager',
    'demoRh': 'RH',
    'offline':
        'Impossible de joindre le serveur. La passerelle est-elle démarrée ?',
    'badCredentials': 'E-mail ou mot de passe incorrect.',
  },
};

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginResult});

  Result<Session>? loginResult;

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
    return const Result.err(Failure.unauthorized());
  }
}

void main() {
  late I18n i18n;
  late ThemeData theme;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = I18n(dicts: {'fr': Map<String, dynamic>.from(_frLogin)});
    theme = AlizeTheme.light();
  });

  Future<void> pumpLogin(
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
          home: const LoginPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  AuthState readAuth(WidgetTester tester) {
    return ProviderScope.containerOf(
      tester.element(find.byType(LoginPage)),
    ).read(authProvider);
  }

  testWidgets('submit with valid credentials yields AuthSignedIn',
      (tester) async {
    final repo = FakeAuthRepository(loginResult: const Result.ok(_session));
    await pumpLogin(tester, repo: repo);

    await tester.enterText(
      find.byKey(LoginPage.emailFieldKey),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(LoginPage.passwordFieldKey),
      'secret',
    );
    await tester.tap(find.widgetWithText(FilledButton, i18n.t('login.submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(readAuth(tester), isA<AuthSignedIn>());
    expect((readAuth(tester) as AuthSignedIn).session.token, 'jwt');
  });

  testWidgets('unauthorized login shows badCredentials', (tester) async {
    final repo = FakeAuthRepository(
      loginResult: const Result.err(Failure.unauthorized()),
    );
    await pumpLogin(tester, repo: repo);

    await tester.enterText(
      find.byKey(LoginPage.emailFieldKey),
      'wrong@rh.local',
    );
    await tester.enterText(
      find.byKey(LoginPage.passwordFieldKey),
      'nope',
    );
    await tester.tap(find.widgetWithText(FilledButton, i18n.t('login.submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('login.badCredentials')), findsOneWidget);
    expect(find.text('E-mail ou mot de passe incorrect.'), findsOneWidget);
    expect(readAuth(tester), isA<AuthSignedOut>());
  });

  testWidgets('network failure shows offline message', (tester) async {
    final repo = FakeAuthRepository(
      loginResult: const Result.err(Failure.network()),
    );
    await pumpLogin(tester, repo: repo);

    await tester.enterText(
      find.byKey(LoginPage.emailFieldKey),
      'a@b.com',
    );
    await tester.enterText(
      find.byKey(LoginPage.passwordFieldKey),
      'secret',
    );
    await tester.tap(find.widgetWithText(FilledButton, i18n.t('login.submit')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('login.offline')), findsOneWidget);
    expect(readAuth(tester), isA<AuthSignedOut>());
  });

  testWidgets('demo chip fills email', (tester) async {
    await pumpLogin(tester, repo: FakeAuthRepository());

    await tester.tap(find.text(i18n.t('login.demoEmployee')));
    await tester.pump();

    final emailField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(LoginPage.emailFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(emailField.controller!.text, 'employee@rh.local');
  });
}
