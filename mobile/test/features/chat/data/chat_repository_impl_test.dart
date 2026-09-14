import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/features/chat/data/datasources/chat_remote.dart';
import 'package:alize_mobile/features/chat/data/models/chat_message_dto.dart';
import 'package:alize_mobile/features/chat/data/models/conversation_dto.dart';
import 'package:alize_mobile/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_upload.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRemote extends Mock implements ChatRemote {}

final _otherJson = {
  'id': 8,
  'email': 'alan@rh.local',
  'role': 'employee',
  'first_name': 'Alan',
  'last_name': 'Turing',
  'job_title': 'Dev',
};

final _messageJson = {
  'id': 10,
  'conversation_id': 1,
  'sender_id': 8,
  'body': 'Hello',
  'created_at': '2026-09-09T10:00:00Z',
  'read_at': null,
  'attachment': {
    'filename': 'photo.png',
    'content_type': 'image/png',
    'byte_size': 2048,
    'url': '/conversations/1/messages/10/file',
  },
};

final _conversationJson = {
  'id': 1,
  'other': _otherJson,
  'last_message': _messageJson,
  'unread_count': 2,
};

void main() {
  late MockChatRemote remote;
  late ChatRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(
      const ChatUpload(
        filename: 'a.txt',
        contentType: 'text/plain',
        bytes: [1],
      ),
    );
  });

  setUp(() {
    remote = MockChatRemote();
    repo = ChatRepositoryImpl(remote: remote);
  });

  test('list maps snake_case conversation JSON to domain', () async {
    when(() => remote.list()).thenAnswer(
      (_) async => [ConversationDto.fromJson(_conversationJson)],
    );

    final result = await repo.list();

    expect(result.isOk, isTrue);
    final conv = result.data!.single;
    expect(conv.id, 1);
    expect(conv.unreadCount, 2);
    expect(conv.other.id, 8);
    expect(conv.other.firstName, 'Alan');
    expect(conv.other.lastName, 'Turing');
    expect(conv.lastMessage?.id, 10);
    expect(conv.lastMessage?.conversationId, 1);
    expect(conv.lastMessage?.senderId, 8);
    expect(conv.lastMessage?.body, 'Hello');
    expect(conv.lastMessage?.createdAt, '2026-09-09T10:00:00Z');
    expect(conv.lastMessage?.readAt, isNull);
    expect(conv.lastMessage?.attachment?.filename, 'photo.png');
    expect(conv.lastMessage?.attachment?.contentType, 'image/png');
    expect(conv.lastMessage?.attachment?.byteSize, 2048);
    expect(
      conv.lastMessage?.attachment?.url,
      '/conversations/1/messages/10/file',
    );
  });

  test('open maps the created conversation', () async {
    when(() => remote.open(8)).thenAnswer(
      (_) async => ConversationDto.fromJson(_conversationJson),
    );

    final result = await repo.open(8);

    expect(result.isOk, isTrue);
    expect(result.data?.id, 1);
    expect(result.data?.other.email, 'alan@rh.local');
    verify(() => remote.open(8)).called(1);
  });

  test('send maps the created message including attachment', () async {
    when(() => remote.send(1, body: 'Hello')).thenAnswer(
      (_) async => ChatMessageDto.fromJson(_messageJson),
    );

    final result = await repo.send(1, body: 'Hello');

    expect(result.isOk, isTrue);
    expect(result.data?.id, 10);
    expect(result.data?.body, 'Hello');
    expect(result.data?.senderId, 8);
    expect(result.data?.attachment?.filename, 'photo.png');
    verify(() => remote.send(1, body: 'Hello')).called(1);
  });

  test('maps Dio 422 to ValidationFailure', () async {
    final options = RequestOptions(path: '/auth/conversations');
    when(() => remote.open(8)).thenThrow(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 422,
          data: {
            'error': 'Vous ne pouvez pas vous écrire à vous-même',
          },
        ),
      ),
    );

    final result = await repo.open(8);

    expect(result.isOk, isFalse);
    expect(result.failure, isA<ValidationFailure>());
    expect(
      (result.failure as ValidationFailure).message,
      'Vous ne pouvez pas vous écrire à vous-même',
    );
  });

  test('maps unexpected errors to ServerFailure instead of throwing', () async {
    when(() => remote.list()).thenThrow(const FormatException('bad json'));

    final result = await repo.list();

    expect(result.isOk, isFalse);
    expect(result.failure, isA<ServerFailure>());
  });

  test('malformed cable payload does not throw', () {
    expect(
      chatPushFromCable({
        'type': 'message',
        'conversation_id': 1,
        'message': {'body': 'missing ids'},
      }),
      isNull,
    );
  });
}
