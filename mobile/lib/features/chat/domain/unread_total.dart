import 'entities/conversation.dart';

int unreadTotal(Iterable<Conversation> conversations) {
  return conversations.fold(0, (sum, c) => sum + c.unreadCount);
}
