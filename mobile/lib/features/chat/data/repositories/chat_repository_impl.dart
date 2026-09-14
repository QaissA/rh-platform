import 'dart:async';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/action_cable_client.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/chat/data/datasources/chat_remote.dart';
import 'package:alize_mobile/features/chat/data/models/chat_message_dto.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_message.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_push.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_upload.dart';
import 'package:alize_mobile/features/chat/domain/entities/conversation.dart';
import 'package:alize_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:dio/dio.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatRemote remote,
    ActionCableClient? cable,
  })  : _remote = remote,
        _cable = cable {
    _cable?.setHandler(_onCable);
  }

  final ChatRemote _remote;
  final ActionCableClient? _cable;
  final _pushes = StreamController<ChatPush>.broadcast();

  @override
  Stream<ChatPush> get pushes => _pushes.stream;

  @override
  void startCable() => _cable?.connect();

  @override
  void stopCable() => _cable?.disconnect();

  @override
  Future<Result<List<Conversation>>> list() => _guard(
        () async =>
            (await _remote.list()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<List<TeamMember>>> directory() => _guard(
        () async =>
            (await _remote.directory()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<Conversation>> open(int userId) => _guard(
        () async => (await _remote.open(userId)).toDomain(),
      );

  @override
  Future<Result<List<ChatMessage>>> history(int conversationId) => _guard(
        () async => (await _remote.history(conversationId))
            .map((e) => e.toDomain())
            .toList(),
      );

  @override
  Future<Result<ChatMessage>> send(
    int conversationId, {
    String body = '',
    ChatUpload? file,
  }) =>
      _guard(
        () async => (await _remote.send(
          conversationId,
          body: body,
          file: file,
        ))
            .toDomain(),
      );

  @override
  Future<Result<Conversation>> markRead(int conversationId) => _guard(
        () async => (await _remote.markRead(conversationId)).toDomain(),
      );

  @override
  Future<Result<List<int>>> fileBytes(ChatMessage message) {
    final url = message.attachment?.url ??
        '/conversations/${message.conversationId}/messages/${message.id}/file';
    return _guard(() => _remote.fileBytes(url));
  }

  void _onCable(Map<String, dynamic> payload) {
    try {
      final push = chatPushFromCable(payload);
      if (push != null) _pushes.add(push);
    } catch (_) {}
  }

  void close() {
    stopCable();
    if (!_pushes.isClosed) {
      _pushes.close();
    }
  }

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    } catch (e) {
      return Result.err(Failure.server(message: '$e'));
    }
  }
}

ChatPush? chatPushFromCable(Map<String, dynamic> payload) {
  try {
    if (payload['type'] != 'message') return null;
    final conversationId = payload['conversation_id'];
    final messageJson = payload['message'];
    if (conversationId is! num || messageJson is! Map) return null;
    return ChatPush(
      conversationId: conversationId.toInt(),
      message: ChatMessageDto.fromJson(
        Map<String, dynamic>.from(messageJson),
      ).toDomain(),
    );
  } catch (_) {
    return null;
  }
}
