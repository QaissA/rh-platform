import 'package:alize_mobile/features/team/domain/entities/team_member.dart';

import 'chat_message.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.other,
    required this.unreadCount,
    this.lastMessage,
  });

  final int id;
  final TeamMember other;
  final ChatMessage? lastMessage;
  final int unreadCount;
}
