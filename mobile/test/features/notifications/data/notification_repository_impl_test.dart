import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/features/notifications/data/datasources/notification_remote.dart';
import 'package:alize_mobile/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.onFetch);

  final ResponseBody Function(RequestOptions options, String body) onFetch;

  RequestOptions? lastOptions;
  String lastBody = '';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    var body = '';
    if (requestStream != null) {
      final chunks = await requestStream.toList();
      if (chunks.isNotEmpty) {
        body = utf8.decode(chunks.expand((c) => c).toList());
      }
    }
    lastOptions = options;
    lastBody = body;
    return onFetch(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

const _notifJson = {
  'id': 9,
  'kind': 'leave',
  'title': 'Demande approuvée',
  'body': 'Vos congés sont validés',
  'link': '/conges',
  'read': false,
  'created_at': '2026-09-09T10:00:00Z',
};

void main() {
  late _ScriptedAdapter adapter;

  NotificationRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return NotificationRepositoryImpl(remote: NotificationRemote(dio));
  }

  test('list maps GET /auth/notifications snake_case JSON', () async {
    final repo = makeRepo(
      (options, _) => _json([
        _notifJson,
        {
          ..._notifJson,
          'id': 10,
          'kind': 'document',
          'title': 'Document prêt',
          'body': null,
          'link': null,
          'read': true,
          'created_at': '2026-09-08T08:30:00Z',
        },
      ]),
    );

    final result = await repo.list();

    expect(adapter.lastOptions?.path, '/auth/notifications');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data, hasLength(2));

    final first = result.data!.first;
    expect(first.id, 9);
    expect(first.kind, 'leave');
    expect(first.title, 'Demande approuvée');
    expect(first.body, 'Vos congés sont validés');
    expect(first.link, '/conges');
    expect(first.read, isFalse);
    expect(first.createdAt, '2026-09-09T10:00:00Z');

    final second = result.data!.last;
    expect(second.id, 10);
    expect(second.body, isNull);
    expect(second.link, isNull);
    expect(second.read, isTrue);
    expect(second.createdAt, '2026-09-08T08:30:00Z');
  });

  test('markRead patches /auth/notifications/:id/read and maps the update',
      () async {
    final repo = makeRepo(
      (options, _) => _json({..._notifJson, 'read': true}),
    );

    final result = await repo.markRead(9);

    expect(adapter.lastOptions?.path, '/auth/notifications/9/read');
    expect(adapter.lastOptions?.method, 'PATCH');
    expect(result.isOk, isTrue);
    expect(result.data?.id, 9);
    expect(result.data?.read, isTrue);
    expect(result.data?.title, 'Demande approuvée');
  });

  test('list maps Dio failures to Result.err', () async {
    final repo = makeRepo(
      (options, _) => _json({'error': 'boom'}, status: 500),
    );

    final result = await repo.list();

    expect(result.isOk, isFalse);
    expect(result.failure, isA<ServerFailure>());
  });
}
