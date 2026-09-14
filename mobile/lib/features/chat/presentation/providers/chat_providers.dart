import 'dart:async';
import 'dart:typed_data';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/action_cable_client.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/chat/data/datasources/chat_remote.dart';
import 'package:alize_mobile/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_push.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_upload.dart';
import 'package:alize_mobile/features/chat/domain/entities/conversation.dart';
import 'package:alize_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:alize_mobile/features/chat/domain/unread_total.dart' as chat;
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final actionCableClientProvider = Provider<ActionCableClient>((ref) {
  final client = ActionCableClient(
    config: ref.watch(appConfigProvider),
    token: () {
      final s = ref.read(authProvider);
      if (s is AuthSignedIn) return s.session.token;
      return null;
    },
  );
  ref.onDispose(client.disconnect);
  return client;
});

final chatRemoteProvider = Provider<ChatRemote>(
  (ref) => ChatRemote(ref.watch(dioProvider)),
);

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final impl = ChatRepositoryImpl(
    remote: ref.watch(chatRemoteProvider),
    cable: ref.watch(actionCableClientProvider),
  );
  ref.onDispose(impl.close);
  return impl;
});

class ChatState {
  const ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.directory = const [],
    this.imageBytes = const {},
    this.activeId,
    this.picking = false,
    this.sending = false,
    this.threadError = false,
  });

  final List<Conversation> conversations;
  final List<ChatMessage> messages;
  final List<TeamMember> directory;
  final Map<int, Uint8List> imageBytes;
  final int? activeId;
  final bool picking;
  final bool sending;
  final bool threadError;

  int get unreadTotal => chat.unreadTotal(conversations);

  Conversation? get active {
    final id = activeId;
    if (id == null) return null;
    for (final conversation in conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  ChatState copyWith({
    List<Conversation>? conversations,
    List<ChatMessage>? messages,
    List<TeamMember>? directory,
    Map<int, Uint8List>? imageBytes,
    bool clearImages = false,
    int? activeId,
    bool clearActive = false,
    bool? picking,
    bool? sending,
    bool? threadError,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      directory: directory ?? this.directory,
      imageBytes: clearImages ? const {} : (imageBytes ?? this.imageBytes),
      activeId: clearActive ? null : (activeId ?? this.activeId),
      picking: picking ?? this.picking,
      sending: sending ?? this.sending,
      threadError: threadError ?? this.threadError,
    );
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);

class ChatController extends Notifier<ChatState> {
  bool _disposed = false;
  int _sessionEpoch = 0;
  int _imageGeneration = 0;
  StreamSubscription<ChatPush>? _pushSub;
  final _fetchingImages = <int>{};

  int? get _meId {
    final auth = ref.read(authProvider);
    if (auth is AuthSignedIn) return auth.session.user.id;
    return null;
  }

  bool _isLive([int? epoch]) {
    if (_disposed) return false;
    if (ref.read(authProvider) is! AuthSignedIn) return false;
    if (epoch != null && epoch != _sessionEpoch) return false;
    return true;
  }

  @override
  ChatState build() {
    _disposed = false;
    final repo = ref.read(chatRepositoryProvider);
    ref.onDispose(() {
      _disposed = true;
      _pushSub?.cancel();
      _pushSub = null;
      repo.stopCable();
    });

    _pushSub = repo.pushes.listen(_onPush);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthSignedIn) {
        unawaited(_start());
      } else if (next is AuthSignedOut) {
        _stop();
      }
    });

    if (ref.read(authProvider) is AuthSignedIn) {
      unawaited(_start());
    }

    return const ChatState();
  }

  Future<void> refresh() async {
    if (!_isLive()) return;
    final epoch = _sessionEpoch;
    final result = await ref.read(chatRepositoryProvider).list();
    if (!_isLive(epoch)) return;
    if (result.isOk && result.data != null) {
      state = state.copyWith(conversations: result.data);
    }
  }

  Future<void> select(int id) async {
    if (!_isLive()) return;
    _imageGeneration++;
    _fetchingImages.clear();
    final epoch = _sessionEpoch;
    final generation = _imageGeneration;
    state = state.copyWith(
      activeId: id,
      picking: false,
      messages: const [],
      clearImages: true,
      threadError: false,
    );
    final repo = ref.read(chatRepositoryProvider);
    final history = await repo.history(id);
    if (!_isLive(epoch) || state.activeId != id) return;
    if (!history.isOk || history.data == null) {
      state = state.copyWith(threadError: true);
      return;
    }
    final messages = history.data!;
    state = state.copyWith(messages: messages, threadError: false);
    unawaited(
      _cacheImages(messages, epoch: epoch, generation: generation),
    );
    final read = await repo.markRead(id);
    if (!_isLive(epoch) || state.activeId != id) return;
    final conv = read.data;
    if (conv != null) {
      _upsert(
        Conversation(
          id: conv.id,
          other: conv.other,
          lastMessage: conv.lastMessage,
          unreadCount: 0,
        ),
      );
    }
  }

  void closeThread() {
    _imageGeneration++;
    _fetchingImages.clear();
    state = state.copyWith(
      clearActive: true,
      messages: const [],
      clearImages: true,
      threadError: false,
    );
  }

  Future<Result<List<TeamMember>>> startPick() async {
    if (!_isLive()) return const Result.err(Failure.unauthorized());
    final epoch = _sessionEpoch;
    state = state.copyWith(picking: true, directory: const []);
    final result = await ref.read(chatRepositoryProvider).directory();
    if (!_isLive(epoch)) return result;
    state = state.copyWith(directory: result.data ?? const []);
    return result;
  }

  void cancelPick() => state = state.copyWith(picking: false);

  Future<Result<Conversation>> openWith(int userId) async {
    if (!_isLive()) return const Result.err(Failure.unauthorized());
    final epoch = _sessionEpoch;
    final result = await ref.read(chatRepositoryProvider).open(userId);
    if (!_isLive(epoch)) return result;
    final conv = result.data;
    if (result.isOk && conv != null) {
      _upsert(conv);
      await select(conv.id);
      if (_isLive(epoch)) state = state.copyWith(picking: false);
    }
    return result;
  }

  Future<Result<ChatMessage>> send({
    String body = '',
    ChatUpload? file,
  }) async {
    final id = state.activeId;
    if (id == null) {
      return const Result.err(Failure.validation('No conversation'));
    }
    if (!_isLive()) return const Result.err(Failure.unauthorized());
    final epoch = _sessionEpoch;
    final generation = _imageGeneration;
    state = state.copyWith(sending: true);
    final result = await ref.read(chatRepositoryProvider).send(
          id,
          body: body,
          file: file,
        );
    if (!_isLive(epoch) || state.activeId != id) return result;
    final msg = result.data;
    if (!result.isOk || msg == null) {
      state = state.copyWith(sending: false);
      return result;
    }

    final messages = state.messages.any((m) => m.id == msg.id)
        ? state.messages
        : [...state.messages, msg];
    state = state.copyWith(sending: false, messages: messages);
    unawaited(_cacheImages([msg], epoch: epoch, generation: generation));
    Conversation? conv;
    for (final candidate in state.conversations) {
      if (candidate.id == id) {
        conv = candidate;
        break;
      }
    }
    if (conv != null) {
      _upsert(
        Conversation(
          id: conv.id,
          other: conv.other,
          lastMessage: msg,
          unreadCount: conv.unreadCount,
        ),
      );
    }
    return result;
  }

  Future<void> _start() async {
    ref.read(chatRepositoryProvider).startCable();
    await refresh();
  }

  void _stop({bool clear = true}) {
    _sessionEpoch++;
    _imageGeneration++;
    _fetchingImages.clear();
    ref.read(chatRepositoryProvider).stopCable();
    if (clear && !_disposed) {
      state = const ChatState();
    }
  }

  void _onPush(ChatPush push) {
    if (!_isLive()) return;
    final existingIndex = state.conversations.indexWhere(
      (c) => c.id == push.conversationId,
    );
    if (existingIndex < 0) {
      unawaited(refresh());
      return;
    }

    final existing = state.conversations[existingIndex];
    final mine = push.message.senderId == _meId;
    final open = state.activeId == push.conversationId;
    final unread =
        mine || open ? existing.unreadCount : existing.unreadCount + 1;
    final next = Conversation(
      id: existing.id,
      other: existing.other,
      lastMessage: push.message,
      unreadCount: unread,
    );
    final conversations = [
      next,
      ...state.conversations.where((c) => c.id != next.id),
    ];

    var messages = state.messages;
    if (open) {
      if (!messages.any((m) => m.id == push.message.id)) {
        messages = [...messages, push.message];
      }
      unawaited(
        _cacheImages(
          [push.message],
          epoch: _sessionEpoch,
          generation: _imageGeneration,
        ),
      );
      if (!mine) {
        unawaited(_markReadSilent(push.conversationId));
      }
    }

    state = state.copyWith(conversations: conversations, messages: messages);
  }

  Future<void> _markReadSilent(int conversationId) async {
    final epoch = _sessionEpoch;
    final result =
        await ref.read(chatRepositoryProvider).markRead(conversationId);
    if (!_isLive(epoch) || state.activeId != conversationId) return;
    final conv = result.data;
    if (conv != null) {
      _upsert(
        Conversation(
          id: conv.id,
          other: conv.other,
          lastMessage: conv.lastMessage,
          unreadCount: 0,
        ),
      );
    }
  }

  void _upsert(Conversation conv) {
    state = state.copyWith(
      conversations: [
        conv,
        ...state.conversations.where((c) => c.id != conv.id),
      ],
    );
  }

  Future<void> _cacheImages(
    List<ChatMessage> messages, {
    required int epoch,
    required int generation,
  }) async {
    if (!_isLive(epoch) || generation != _imageGeneration) return;
    final repo = ref.read(chatRepositoryProvider);
    for (final msg in messages) {
      final attachment = msg.attachment;
      if (attachment == null || !attachment.contentType.startsWith('image/')) {
        continue;
      }
      if (state.imageBytes.containsKey(msg.id) ||
          _fetchingImages.contains(msg.id)) {
        continue;
      }
      _fetchingImages.add(msg.id);
      final result = await repo.fileBytes(msg);
      _fetchingImages.remove(msg.id);
      if (!_isLive(epoch) || generation != _imageGeneration) return;
      if (state.activeId == null) return;
      final raw = result.data;
      if (result.isOk && raw != null) {
        final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
        state = state.copyWith(
          imageBytes: {...state.imageBytes, msg.id: bytes},
        );
      }
    }
  }
}
