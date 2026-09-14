import 'package:alize_mobile/features/chat/domain/entities/conversation.dart';
import 'package:alize_mobile/features/chat/domain/unread_total.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:flutter_test/flutter_test.dart';

const _alice = TeamMember(
  id: 8,
  email: 'alice@rh.local',
  role: 'employee',
  firstName: 'Alice',
  lastName: 'Dupont',
);

const _bob = TeamMember(
  id: 9,
  email: 'bob@rh.local',
  role: 'manager',
  firstName: 'Bob',
  lastName: 'Martin',
);

void main() {
  test('unread total is the sum of unread_count', () {
    const conversations = [
      Conversation(id: 1, other: _alice, lastMessage: null, unreadCount: 2),
      Conversation(id: 2, other: _bob, lastMessage: null, unreadCount: 3),
      Conversation(id: 3, other: _alice, lastMessage: null, unreadCount: 0),
    ];

    expect(unreadTotal(conversations), 5);
  });

  test('unread total is zero for an empty list', () {
    expect(unreadTotal(const []), 0);
  });
}
