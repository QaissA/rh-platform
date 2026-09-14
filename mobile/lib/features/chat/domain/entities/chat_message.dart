import 'chat_attachment.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    this.body,
    this.readAt,
    this.attachment,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String? body;
  final String createdAt;
  final String? readAt;
  final ChatAttachment? attachment;
}
