import 'package:alize_mobile/features/team/data/models/team_member_dto.dart';

import '../../domain/entities/conversation.dart';
import 'chat_message_dto.dart';

class ConversationDto {
  const ConversationDto({
    required this.id,
    required this.other,
    required this.unreadCount,
    this.lastMessage,
  });

  final int id;
  final TeamMemberDto other;
  final ChatMessageDto? lastMessage;
  final int unreadCount;

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    final rawLast = json['last_message'];
    return ConversationDto(
      id: json['id'] as int,
      other: TeamMemberDto.fromJson(
        Map<String, dynamic>.from(json['other'] as Map),
      ),
      lastMessage: rawLast is Map
          ? ChatMessageDto.fromJson(Map<String, dynamic>.from(rawLast))
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Conversation toDomain() => Conversation(
        id: id,
        other: other.toDomain(),
        lastMessage: lastMessage?.toDomain(),
        unreadCount: unreadCount,
      );
}
