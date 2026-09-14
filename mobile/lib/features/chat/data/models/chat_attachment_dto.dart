import '../../domain/entities/chat_attachment.dart';

class ChatAttachmentDto {
  const ChatAttachmentDto({
    required this.filename,
    required this.contentType,
    required this.byteSize,
    required this.url,
  });

  final String filename;
  final String contentType;
  final int byteSize;
  final String url;

  factory ChatAttachmentDto.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentDto(
      filename: json['filename'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      byteSize: (json['byte_size'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
    );
  }

  ChatAttachment toDomain() => ChatAttachment(
        filename: filename,
        contentType: contentType,
        byteSize: byteSize,
        url: url,
      );
}
