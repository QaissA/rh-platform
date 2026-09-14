import 'dart:convert';

import 'package:alize_mobile/core/network/action_cable_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignores welcome frames', () {
    expect(parseCableFrame('{"type":"welcome"}'), isNull);
  });

  test('ignores ping frames', () {
    expect(parseCableFrame('{"type":"ping","message":123}'), isNull);
  });

  test('ignores confirm_subscription frames', () {
    expect(
      parseCableFrame(
        '{"type":"confirm_subscription","identifier":"{\\"channel\\":\\"ChatChannel\\"}"}',
      ),
      isNull,
    );
  });

  test('forwards nested message-type payloads', () {
    final raw = jsonEncode({
      'identifier': '{"channel":"ChatChannel"}',
      'message': {
        'type': 'message',
        'conversation_id': 9,
        'message': {
          'id': 3,
          'conversation_id': 9,
          'sender_id': 2,
          'body': 'hi',
          'created_at': '2026-09-09T10:00:00Z',
          'read_at': null,
        },
      },
    });

    final payload = parseCableFrame(raw);

    expect(payload, isNotNull);
    expect(payload!['type'], 'message');
    expect(payload['conversation_id'], 9);
    expect((payload['message'] as Map)['body'], 'hi');
    expect((payload['message'] as Map)['id'], 3);
  });
}
