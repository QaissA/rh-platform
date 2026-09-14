import 'chat_message.dart';

class ChatPush {
  const ChatPush({
    required this.conversationId,
    required this.message,
  });

  final int conversationId;
  final ChatMessage message;
}
