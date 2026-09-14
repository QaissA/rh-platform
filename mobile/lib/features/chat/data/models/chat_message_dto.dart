import '../../domain/entities/chat_message.dart';
import 'chat_attachment_dto.dart';

class ChatMessageDto {
  const ChatMessageDto({
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
  final ChatAttachmentDto? attachment;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    final rawAttachment = json['attachment'];
    return ChatMessageDto(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      senderId: json['sender_id'] as int,
      body: json['body'] as String?,
      createdAt: json['created_at'] as String,
      readAt: json['read_at'] as String?,
      attachment: rawAttachment is Map
          ? ChatAttachmentDto.fromJson(Map<String, dynamic>.from(rawAttachment))
          : null,
    );
  }

  ChatMessage toDomain() => ChatMessage(
        id: id,
        conversationId: conversationId,
        senderId: senderId,
        body: body,
        createdAt: createdAt,
        readAt: readAt,
        attachment: attachment?.toDomain(),
      );
}
