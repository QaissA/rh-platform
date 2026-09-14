import 'package:alize_mobile/app.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/router/app_router.dart';
import 'package:alize_mobile/core/router/roles.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/core/theme/theme_controller.dart';
import 'package:alize_mobile/core/widgets/app_shell.dart';
import 'package:alize_mobile/core/widgets/lang_switcher.dart';
import 'package:alize_mobile/features/admin_users/presentation/pages/admin_users_page.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/pages/change_password_page.dart';
import 'package:alize_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/dashboard/presentation/pages/home_page.dart';
import 'package:alize_mobile/features/more/presentation/pages/more_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

AuthSignedIn signedIn({
  String role = 'employee',
  bool mustChangePassword = false,
}) {
  return AuthSignedIn(
    Session(
      token: 'jwt',
      user: User(
        id: 1,
        email: 'a@b.com',
        role: role,
        firstName: 'Ada',
        lastName: 'Lovelace',
        mustChangePassword: mustChangePassword,
      ),
    ),
  );
}

class StaticAuthNotifier extends AuthNotifier {
  StaticAuthNotifier(this._initial);

  final AuthState _initial;

  @override
  AuthState build() => _initial;
}

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  group('roles', () {
    test('isAdmin is only admin', () {
      expect(isAdmin('admin'), isTrue);
      expect(isAdmin('rh'), isFalse);
      expect(isAdmin('manager'), isFalse);
      expect(isAdmin('employee'), isFalse);
    });

    test('isRh includes rh and admin', () {
      expect(isRh('rh'), isTrue);
      expect(isRh('admin'), isTrue);
      expect(isRh('manager'), isFalse);
      expect(isRh('employee'), isFalse);
    });

    test('isManager includes manager, rh, and admin', () {
      expect(isManager('manager'), isTrue);
      expect(isManager('rh'), isTrue);
      expect(isManager('admin'), isTrue);
      expect(isManager('employee'), isFalse);
      expect(isManager('lead'), isFalse);
    });
  });

  group('redirectFor', () {
    test('AuthUnknown stays put to avoid a login flash', () {
      expect(
        redirectFor(auth: const AuthUnknown(), path: '/dashboard'),
        isNull,
      );
      expect(redirectFor(auth: const AuthUnknown(), path: '/login'), isNull);
      expect(redirectFor(auth: const AuthUnknown(), path: '/'), isNull);
      expect(
        redirectFor(auth: const AuthUnknown(), path: '/utilisateurs'),
        isNull,
      );
    });

    test('signed out away from login goes to login', () {
      expect(
        redirectFor(auth: const AuthSignedOut(), path: '/dashboard'),
        '/login',
      );
      expect(redirectFor(auth: const AuthSignedOut(), path: '/'), '/login');
      expect(
        redirectFor(auth: const AuthSignedOut(), path: '/conges'),
        '/login',
      );
    });

    test('signed out on login stays', () {
      expect(redirectFor(auth: const AuthSignedOut(), path: '/login'), isNull);
    });

    test('mustChangePassword away from change-password goes there', () {
      final auth = signedIn(mustChangePassword: true);
      expect(redirectFor(auth: auth, path: '/dashboard'), '/change-password');
      expect(redirectFor(auth: auth, path: '/login'), '/change-password');
      expect(redirectFor(auth: auth, path: '/conges'), '/change-password');
    });

    test('mustChangePassword on change-password stays', () {
      expect(
        redirectFor(
          auth: signedIn(mustChangePassword: true),
          path: '/change-password',
        ),
        isNull,
      );
    });

    test('password already changed leaves change-password for dashboard', () {
      expect(
        redirectFor(auth: signedIn(), path: '/change-password'),
        '/dashboard',
      );
    });

    test('signed in on login goes to dashboard', () {
      expect(redirectFor(auth: signedIn(), path: '/login'), '/dashboard');
    });

    test('signed in on splash goes to dashboard', () {
      expect(redirectFor(auth: signedIn(), path: '/'), '/dashboard');
    });

    test('not manager on validation-conges goes to dashboard', () {
      expect(
        redirectFor(auth: signedIn(role: 'employee'), path: '/validation-conges'),
        '/dashboard',
      );
      expect(
        redirectFor(auth: signedIn(role: 'lead'), path: '/validation-conges'),
        '/dashboard',
      );
    });

    test('manager rh admin may open validation-conges', () {
      expect(
        redirectFor(auth: signedIn(role: 'manager'), path: '/validation-conges'),
        isNull,
      );
      expect(
        redirectFor(auth: signedIn(role: 'rh'), path: '/validation-conges'),
        isNull,
      );
      expect(
        redirectFor(auth: signedIn(role: 'admin'), path: '/validation-conges'),
        isNull,
      );
    });

    test('not rh on documents-rh or dossiers goes to dashboard', () {
      expect(
        redirectFor(auth: signedIn(role: 'employee'), path: '/documents-rh'),
        '/dashboard',
      );
      expect(
        redirectFor(auth: signedIn(role: 'manager'), path: '/dossiers'),
        '/dashboard',
      );
      expect(
        redirectFor(auth: signedIn(role: 'employee'), path: '/documents-rh/3'),
        '/dashboard',
      );
      expect(
        redirectFor(auth: signedIn(role: 'manager'), path: '/dossiers/9'),
        '/dashboard',
      );
    });

    test('rh and admin may open documents-rh and dossiers', () {
      expect(
        redirectFor(auth: signedIn(role: 'rh'), path: '/documents-rh'),
        isNull,
      );
      expect(
        redirectFor(auth: signedIn(role: 'admin'), path: '/dossiers'),
        isNull,
      );
    });

    test('not admin on admin org routes goes to dashboard', () {
      for (final path in [
        '/business-units',
        '/projets',
        '/equipes',
        '/utilisateurs',
      ]) {
        expect(
          redirectFor(auth: signedIn(role: 'rh'), path: path),
          '/dashboard',
          reason: path,
        );
        expect(
          redirectFor(auth: signedIn(role: 'employee'), path: path),
          '/dashboard',
          reason: path,
        );
      }
    });

    test('admin may open admin org routes', () {
      for (final path in [
        '/business-units',
        '/projets',
        '/equipes',
        '/utilisateurs',
      ]) {
        expect(
          redirectFor(auth: signedIn(role: 'admin'), path: path),
          isNull,
          reason: path,
        );
      }
    });

    test('employee may open dashboard leave team messages more documents', () {
      for (final path in [
        '/dashboard',
        '/conges',
        '/equipe',
        '/messages',
        '/more',
        '/documents',
        '/parametres',
      ]) {
        expect(
          redirectFor(auth: signedIn(), path: path),
          isNull,
          reason: path,
        );
      }
    });

    test('equipe is not treated as admin equipes', () {
      expect(
        redirectFor(auth: signedIn(role: 'employee'), path: '/equipe'),
        isNull,
      );
    });
  });

  group('GoRouter widget redirects', () {
    Future<GoRouter> pumpApp(
      WidgetTester tester, {
      required AuthState auth,
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            i18nProvider.overrideWith((ref) => I18nController(i18n)),
            themePrefsProvider.overrideWithValue(MemoryThemePrefs()),
            sessionStoreProvider.overrideWithValue(MemorySessionStore()),
            authProvider.overrideWith(() => StaticAuthNotifier(auth)),
          ],
          child: const AlizeApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      return ProviderScope.containerOf(
        tester.element(find.byType(AlizeApp)),
      ).read(routerProvider);
    }

    testWidgets('AuthUnknown on splash does not bounce to login',
        (tester) async {
      final router = await pumpApp(tester, auth: const AuthUnknown());

      expect(router.state.uri.path, '/');
      expect(find.byType(LoginPage), findsNothing);
      expect(find.text('Alizé'), findsWidgets);
    });

    testWidgets('signed out is sent to login', (tester) async {
      final router = await pumpApp(tester, auth: const AuthSignedOut());

      expect(router.state.uri.path, '/login');
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('signed in lands on dashboard shell', (tester) async {
      final router = await pumpApp(tester, auth: signedIn());

      expect(router.state.uri.path, '/dashboard');
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text(i18n.t('dashboard.leaveBalance')), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).labelBehavior,
        NavigationDestinationLabelBehavior.alwaysHide,
      );
      expect(find.byKey(AppShell.floatingNavBarKey), findsOneWidget);
      final bar = tester.widget<DecoratedBox>(
        find.byKey(AppShell.floatingNavBarKey),
      );
      final decoration = bar.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(24));
      expect(decoration.color, AlizeColors.light.surface);
      expect(decoration.border, isNotNull);
      expect(find.byType(LangSwitcher), findsOneWidget);
    });

    testWidgets('mustChangePassword opens change-password', (tester) async {
      final router = await pumpApp(
        tester,
        auth: signedIn(mustChangePassword: true),
      );

      expect(router.state.uri.path, '/change-password');
      expect(find.byType(ChangePasswordPage), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('employee is bounced off utilisateurs', (tester) async {
      final router = await pumpApp(tester, auth: signedIn());
      router.go('/utilisateurs');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(router.state.uri.path, '/dashboard');
      expect(find.text('/utilisateurs'), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('admin can open utilisateurs', (tester) async {
      final router = await pumpApp(tester, auth: signedIn(role: 'admin'));
      router.go('/utilisateurs');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(router.state.uri.path, '/utilisateurs');
      expect(find.byType(AdminUsersPage), findsOneWidget);
    });

    testWidgets('employee More hides RH and admin links', (tester) async {
      final router = await pumpApp(tester, auth: signedIn());
      router.go('/more');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(router.state.uri.path, '/more');
      expect(find.byType(MorePage), findsOneWidget);
      expect(find.text(i18n.t('nav.dashboard')), findsWidgets);
      expect(find.text(i18n.t('nav.leave')), findsWidgets);
      expect(find.text(i18n.t('nav.team')), findsWidgets);
      expect(find.text(i18n.t('nav.messages')), findsWidgets);
      expect(find.text(i18n.t('nav.documents')), findsOneWidget);
      expect(find.text(i18n.t('nav.settings')), findsOneWidget);
      expect(find.text(i18n.t('nav.users')), findsNothing);
      expect(find.text(i18n.t('nav.leaveReview')), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(MorePage.logoutTileKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(MorePage.logoutTileKey), findsOneWidget);
    });

    testWidgets('admin More shows role-gated RH and admin links',
        (tester) async {
      final router = await pumpApp(tester, auth: signedIn(role: 'admin'));
      router.go('/more');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(router.state.uri.path, '/more');
      expect(find.byType(MorePage), findsOneWidget);
      expect(find.text(i18n.t('nav.dashboard')), findsWidgets);
      expect(find.text(i18n.t('nav.documents')), findsOneWidget);
      expect(find.text(i18n.t('nav.settings')), findsOneWidget);
      expect(find.text(i18n.t('nav.leaveReview')), findsOneWidget);
      expect(find.text(i18n.t('nav.documentsRh')), findsOneWidget);
      expect(find.text(i18n.t('nav.users')), findsOneWidget);
      expect(find.text(i18n.t('nav.units')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(MorePage.logoutTileKey),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(MorePage.logoutTileKey), findsOneWidget);
    });
  });
}
