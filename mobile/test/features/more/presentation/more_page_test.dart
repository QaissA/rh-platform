import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_push.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_upload.dart';
import 'package:alize_mobile/features/chat/domain/entities/conversation.dart';
import 'package:alize_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:alize_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:alize_mobile/features/more/presentation/pages/more_page.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class StaticAuth extends AuthNotifier {
  StaticAuth(this.role);

  final String role;

  @override
  AuthState build() => AuthSignedIn(
        Session(
          token: 'jwt',
          user: User(
            id: 1,
            email: 'a@b.com',
            role: role,
            firstName: 'Ada',
            lastName: 'Lovelace',
          ),
        ),
      );
}

class SeededInboxBadge extends InboxBadgeNotifier {
  SeededInboxBadge(this.seed);

  final InboxBadgeState seed;

  @override
  InboxBadgeState build() => seed;
}

class FakeChatRepository implements ChatRepository {
  @override
  Future<Result<List<Conversation>>> list() async => const Result.ok([]);

  @override
  Future<Result<List<TeamMember>>> directory() async => const Result.ok([]);

  @override
  Future<Result<Conversation>> open(int userId) async {
    return const Result.err(Failure.network());
  }

  @override
  Future<Result<List<ChatMessage>>> history(int conversationId) async {
    return const Result.ok([]);
  }

  @override
  Future<Result<ChatMessage>> send(
    int conversationId, {
    String body = '',
    ChatUpload? file,
  }) async {
    return const Result.err(Failure.network());
  }

  @override
  Future<Result<Conversation>> markRead(int conversationId) async {
    return const Result.err(Failure.network());
  }

  @override
  Future<Result<List<int>>> fileBytes(ChatMessage message) async {
    return const Result.err(Failure.network());
  }

  @override
  void startCable() {}

  @override
  void stopCable() {}

  @override
  Stream<ChatPush> get pushes => const Stream.empty();
}

List<Override> moreOverrides({
  required I18n i18n,
  required AuthNotifier Function() auth,
  InboxBadgeState badges = const InboxBadgeState(),
}) {
  return [
    i18nProvider.overrideWith((ref) => I18nController(i18n)),
    authProvider.overrideWith(auth),
    inboxBadgeProvider.overrideWith(() => SeededInboxBadge(badges)),
    chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
  ];
}

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets('More list tiles show leave and document queue counts',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/more',
      routes: [
        GoRoute(
          path: '/more',
          builder: (context, state) => const Scaffold(body: MorePage()),
        ),
        GoRoute(
          path: '/validation-conges',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/documents-rh',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/documents',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/parametres',
          builder: (context, state) => const SizedBox.shrink(),
        ),
        GoRoute(
          path: '/dossiers',
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: moreOverrides(
          i18n: i18n,
          auth: () => StaticAuth('admin'),
          badges: const InboxBadgeState(leaveQueue: 4, docQueue: 2),
        ),
        child: MaterialApp.router(
          theme: AlizeTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('nav.dashboard')), findsOneWidget);
    expect(find.text(i18n.t('nav.leave')), findsOneWidget);
    expect(find.text(i18n.t('nav.team')), findsOneWidget);
    expect(find.text(i18n.t('nav.messages')), findsOneWidget);
    expect(find.text(i18n.t('nav.documents')), findsOneWidget);
    expect(find.text(i18n.t('nav.settings')), findsOneWidget);
    expect(find.text(i18n.t('nav.leaveReview')), findsOneWidget);
    expect(find.text(i18n.t('nav.documentsRh')), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(MorePage.logoutTileKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(MorePage.logoutTileKey), findsOneWidget);
    expect(find.text(i18n.t('nav.logout')), findsOneWidget);
  });

  testWidgets('logout tile signs the user out', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = LogoutAuth();
    await tester.pumpWidget(
      ProviderScope(
        overrides: moreOverrides(i18n: i18n, auth: () => auth),
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const Scaffold(body: MorePage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.scrollUntilVisible(
      find.byKey(MorePage.logoutTileKey),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(MorePage.logoutTileKey));
    await tester.pump();

    expect(auth.logoutCalls, 1);
    expect(auth.state, isA<AuthSignedOut>());
  });
}

class LogoutAuth extends AuthNotifier {
  var logoutCalls = 0;

  @override
  AuthState build() => const AuthSignedIn(
        Session(
          token: 'jwt',
          user: User(
            id: 1,
            email: 'a@b.com',
            role: 'employee',
            firstName: 'Ada',
            lastName: 'Lovelace',
          ),
        ),
      );

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    state = const AuthSignedOut();
  }
}
