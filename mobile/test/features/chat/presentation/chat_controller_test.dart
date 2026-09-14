import 'dart:async';

import 'package:alize_mobile/core/config/app_config.dart';
import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/action_cable_client.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/chat/data/datasources/chat_remote.dart';
import 'package:alize_mobile/features/chat/data/models/chat_message_dto.dart';
import 'package:alize_mobile/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_attachment.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_push.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_upload.dart';
import 'package:alize_mobile/features/chat/domain/entities/conversation.dart';
import 'package:alize_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:alize_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRemote extends Mock implements ChatRemote {}

const _user = User(
  id: 1,
  email: 'ada@rh.local',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

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

const _msgA = ChatMessage(
  id: 11,
  conversationId: 1,
  senderId: 8,
  body: 'from A',
  createdAt: '2026-09-09T10:00:00Z',
);

const _msgB = ChatMessage(
  id: 22,
  conversationId: 2,
  senderId: 9,
  body: 'from B',
  createdAt: '2026-09-09T10:01:00Z',
);

const _photo = ChatMessage(
  id: 30,
  conversationId: 1,
  senderId: 8,
  body: null,
  createdAt: '2026-09-09T10:02:00Z',
  attachment: ChatAttachment(
    filename: 'pic.png',
    contentType: 'image/png',
    byteSize: 4,
    url: '/conversations/1/messages/30/file',
  ),
);

const _convA = Conversation(id: 1, other: _alice, unreadCount: 1);
const _convB = Conversation(id: 2, other: _bob, unreadCount: 0);

class ScriptedAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthSignedIn(Session(token: 'jwt', user: _user));

  void signOut() => state = const AuthSignedOut();
}

class ScriptedChatRepository implements ChatRepository {
  ScriptedChatRepository({
    this.conversations = const [_convA, _convB],
  });

  final List<Conversation> conversations;
  final historyGates = <int, Completer<Result<List<ChatMessage>>>>{};
  Completer<Result<List<int>>>? fileBytesCompleter;
  int startCableCount = 0;
  int stopCableCount = 0;
  Result<ChatMessage>? sendResult;

  Completer<Result<List<ChatMessage>>> historyGate(int id) {
    return historyGates.putIfAbsent(id, Completer.new);
  }

  @override
  Future<Result<List<Conversation>>> list() async => Result.ok(conversations);

  @override
  Future<Result<List<TeamMember>>> directory() async => const Result.ok([]);

  @override
  Future<Result<Conversation>> open(int userId) async {
    return const Result.err(Failure.network());
  }

  @override
  Future<Result<List<ChatMessage>>> history(int conversationId) {
    return historyGate(conversationId).future;
  }

  @override
  Future<Result<ChatMessage>> send(
    int conversationId, {
    String body = '',
    ChatUpload? file,
  }) async {
    return sendResult ??
        Result.ok(
          ChatMessage(
            id: 99,
            conversationId: conversationId,
            senderId: 1,
            body: body,
            createdAt: '2026-09-09T11:00:00Z',
          ),
        );
  }

  @override
  Future<Result<Conversation>> markRead(int conversationId) async {
    final conv = conversations.firstWhere((c) => c.id == conversationId);
    return Result.ok(
      Conversation(
        id: conv.id,
        other: conv.other,
        lastMessage: conv.lastMessage,
        unreadCount: 0,
      ),
    );
  }

  @override
  Future<Result<List<int>>> fileBytes(ChatMessage message) {
    return (fileBytesCompleter ??= Completer()).future;
  }

  @override
  void startCable() => startCableCount++;

  @override
  void stopCable() => stopCableCount++;

  @override
  Stream<ChatPush> get pushes => const Stream.empty();
}

void main() {
  late ScriptedChatRepository repo;
  late ScriptedAuth auth;

  ProviderContainer createContainer() {
    auth = ScriptedAuth();
    repo = ScriptedChatRepository();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => auth),
        chatRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('late history for conversation A does not replace B', () async {
    final container = createContainer();
    final controller = container.read(chatControllerProvider.notifier);

    final selectA = controller.select(1);
    final selectB = controller.select(2);
    repo.historyGate(2).complete(const Result.ok([_msgB]));
    await selectB;

    expect(container.read(chatControllerProvider).activeId, 2);
    expect(container.read(chatControllerProvider).messages.single.body, 'from B');

    repo.historyGate(1).complete(const Result.ok([_msgA]));
    await selectA;

    expect(container.read(chatControllerProvider).activeId, 2);
    expect(container.read(chatControllerProvider).messages, hasLength(1));
    expect(container.read(chatControllerProvider).messages.single.body, 'from B');
  });

  test('history failure sets threadError instead of an empty success', () async {
    final container = createContainer();
    final controller = container.read(chatControllerProvider.notifier);

    repo.historyGate(1).complete(const Result.err(Failure.network()));
    await controller.select(1);

    final state = container.read(chatControllerProvider);
    expect(state.activeId, 1);
    expect(state.messages, isEmpty);
    expect(state.threadError, isTrue);
  });

  test('send succeeds with no Action Cable client', () async {
    final remote = MockChatRemote();
    when(() => remote.send(1, body: 'Hi')).thenAnswer(
      (_) async => ChatMessageDto.fromJson({
        'id': 10,
        'conversation_id': 1,
        'sender_id': 1,
        'body': 'Hi',
        'created_at': '2026-09-09T10:00:00Z',
        'read_at': null,
      }),
    );
    final chatRepo = ChatRepositoryImpl(remote: remote);

    final result = await chatRepo.send(1, body: 'Hi');

    expect(result.isOk, isTrue);
    expect(result.data?.body, 'Hi');
  });

  test('send succeeds when the cable connect throws', () async {
    final remote = MockChatRemote();
    when(() => remote.send(1, body: 'Hi')).thenAnswer(
      (_) async => ChatMessageDto.fromJson({
        'id': 10,
        'conversation_id': 1,
        'sender_id': 1,
        'body': 'Hi',
        'created_at': '2026-09-09T10:00:00Z',
        'read_at': null,
      }),
    );
    final cable = ActionCableClient(
      config: const AppConfig(apiBaseUrl: 'http://localhost:3000'),
      token: () => 'jwt',
      connect: (_) => throw StateError('dead cable'),
      scheduleReconnect: (_, _) {},
    );
    final chatRepo = ChatRepositoryImpl(remote: remote, cable: cable);
    addTearDown(chatRepo.close);
    chatRepo.startCable();

    final result = await chatRepo.send(1, body: 'Hi');

    expect(result.isOk, isTrue);
    expect(result.data?.body, 'Hi');
  });

  test('in-flight image bytes are dropped after logout', () async {
    final container = createContainer();
    final controller = container.read(chatControllerProvider.notifier);
    repo.fileBytesCompleter = Completer();

    repo.historyGate(1).complete(const Result.ok([_photo]));
    await controller.select(1);
    expect(container.read(chatControllerProvider).imageBytes, isEmpty);

    auth.signOut();
    expect(container.read(chatControllerProvider).imageBytes, isEmpty);

    repo.fileBytesCompleter!.complete(const Result.ok([1, 2, 3, 4]));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(chatControllerProvider).imageBytes, isEmpty);
    expect(container.read(chatControllerProvider).conversations, isEmpty);
  });

  test('closeThread clears imageBytes and ignores late fileBytes', () async {
    final container = createContainer();
    final controller = container.read(chatControllerProvider.notifier);
    repo.fileBytesCompleter = Completer();

    repo.historyGate(1).complete(const Result.ok([_photo]));
    await controller.select(1);
    repo.fileBytesCompleter!.complete(const Result.ok([9, 8, 7]));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(chatControllerProvider).imageBytes.containsKey(30), isTrue);

    controller.closeThread();
    expect(container.read(chatControllerProvider).imageBytes, isEmpty);
    expect(container.read(chatControllerProvider).activeId, isNull);
  });
}
