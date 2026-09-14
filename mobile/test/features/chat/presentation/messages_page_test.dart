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
import 'package:alize_mobile/features/chat/presentation/pages/messages_page.dart';
import 'package:alize_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({this.conversations = const []});

  final List<Conversation> conversations;

  @override
  Future<Result<List<Conversation>>> list() async => Result.ok(conversations);

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

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthSignedIn(
        Session(
          token: 'jwt',
          user: User(
            id: 1,
            email: 'ada@rh.local',
            role: 'employee',
            firstName: 'Ada',
            lastName: 'Lovelace',
          ),
        ),
      );
}

const _alice = TeamMember(
  id: 8,
  email: 'alice@rh.local',
  role: 'employee',
  firstName: 'Alice',
  lastName: 'Dupont',
);

const _bob = TeamMember(
  id: 9,
  email: 'bob@rh.local',
  role: 'manager',
  firstName: 'Bob',
  lastName: 'Martin',
);

const _conversations = [
  Conversation(id: 1, other: _alice, lastMessage: null, unreadCount: 2),
  Conversation(id: 2, other: _bob, lastMessage: null, unreadCount: 0),
];

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets(
    'conversation list renders the other person name for two fake conversations',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            i18nProvider.overrideWith((ref) => I18nController(i18n)),
            authProvider.overrideWith(_SignedInAuth.new),
            chatRepositoryProvider.overrideWithValue(
              FakeChatRepository(conversations: _conversations),
            ),
          ],
          child: MaterialApp(
            theme: AlizeTheme.light(),
            home: const MessagesPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Alice Dupont'), findsOneWidget);
      expect(find.text('Bob Martin'), findsOneWidget);
    },
  );
}
