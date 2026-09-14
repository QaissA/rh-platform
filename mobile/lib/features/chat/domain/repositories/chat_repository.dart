import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';

import '../entities/chat_message.dart';
import '../entities/chat_push.dart';
import '../entities/chat_upload.dart';
import '../entities/conversation.dart';

abstract class ChatRepository {
  Future<Result<List<Conversation>>> list();

  Future<Result<List<TeamMember>>> directory();

  Future<Result<Conversation>> open(int userId);

  Future<Result<List<ChatMessage>>> history(int conversationId);

  Future<Result<ChatMessage>> send(
    int conversationId, {
    String body = '',
    ChatUpload? file,
  });

  Future<Result<Conversation>> markRead(int conversationId);

  Future<Result<List<int>>> fileBytes(ChatMessage message);

  void startCable();

  void stopCable();

  Stream<ChatPush> get pushes;
}
