import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:alize_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/notification_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/widgets/notifications_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _user = User(
  id: 1,
  email: 'ada@rh.local',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

const _unreadLeave = AppNotification(
  id: 9,
  kind: 'leave',
  title: 'Demande approuvée',
  body: 'Vos congés sont validés',
  link: '/conges',
  read: false,
  createdAt: '2026-09-09T10:00:00Z',
);

const _unreadExternal = AppNotification(
  id: 11,
  kind: 'info',
  title: 'External notice',
  link: 'https://example.com/docs',
  read: false,
  createdAt: '2026-09-09T11:00:00Z',
);

class StaticAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthSignedIn(Session(token: 'jwt', user: _user));
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({required this.items});

  List<AppNotification> items;
  final marked = <int>[];

  @override
  Future<Result<List<AppNotification>>> list() async => Result.ok(items);

  @override
  Future<Result<AppNotification>> markRead(int id) async {
    marked.add(id);
    items = [
      for (final n in items)
        if (n.id == id)
          AppNotification(
            id: n.id,
            kind: n.kind,
            title: n.title,
            body: n.body,
            link: n.link,
            read: true,
            createdAt: n.createdAt,
          )
        else
          n,
    ];
    return Result.ok(items.firstWhere((n) => n.id == id));
  }
}

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  Future<GoRouter> pumpBell(
    WidgetTester tester, {
    required FakeNotificationRepository repo,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => Scaffold(
            appBar: AppBar(actions: const [NotificationsBell()]),
            body: const Text('dash'),
          ),
        ),
        GoRoute(
          path: '/conges',
          builder: (context, state) => const Text('leave destination'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          authProvider.overrideWith(StaticAuth.new),
          notificationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(
          theme: AlizeTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotificationsBell)),
    );
    await container.read(notificationsControllerProvider.notifier).load();
    await tester.pump();
    return router;
  }

  testWidgets('bell shows unread count then tap marks read and goes in-app',
      (tester) async {
    final repo = FakeNotificationRepository(items: const [_unreadLeave]);
    final router = await pumpBell(tester, repo: repo);

    expect(find.byType(Badge), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Badge),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(i18n.t('nav.notifications')));
    await tester.pumpAndSettle();

    expect(find.text('Demande approuvée'), findsOneWidget);

    await tester.tap(find.text('Demande approuvée'));
    await tester.pumpAndSettle();

    expect(repo.marked, [9]);
    expect(find.text('Demande approuvée'), findsNothing);
    expect(router.state.uri.path, '/conges');
    expect(find.text('leave destination'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Badge),
        matching: find.text('1'),
      ),
      findsNothing,
    );
  });

  testWidgets('tap marks read but ignores an external link', (tester) async {
    final repo = FakeNotificationRepository(items: const [_unreadExternal]);
    final router = await pumpBell(tester, repo: repo);

    await tester.tap(find.byTooltip(i18n.t('nav.notifications')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('External notice'));
    await tester.pumpAndSettle();

    expect(repo.marked, [11]);
    expect(router.state.uri.path, '/dashboard');
    expect(find.text('dash'), findsOneWidget);
  });

  testWidgets('empty panel shows notif.empty', (tester) async {
    final repo = FakeNotificationRepository(items: const []);
    await pumpBell(tester, repo: repo);

    await tester.tap(find.byTooltip(i18n.t('nav.notifications')));
    await tester.pumpAndSettle();

    expect(find.text(i18n.t('notif.empty')), findsOneWidget);
  });
}
