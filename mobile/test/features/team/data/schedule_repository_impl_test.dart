import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/features/team/data/datasources/schedule_remote.dart';
import 'package:alize_mobile/features/team/data/repositories/schedule_repository_impl.dart';
import 'package:alize_mobile/features/team/domain/entities/new_presence.dart';
import 'package:alize_mobile/features/team/domain/entities/presence_status.dart';
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

void main() {
  late _ScriptedAdapter adapter;
  late ScheduleRepositoryImpl repo;

  ScheduleRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return ScheduleRepositoryImpl(remote: ScheduleRemote(dio));
  }

  test('getSchedule maps snake_case entries including holiday', () async {
    repo = makeRepo(
      (options, _) => _json({
        'start': '2026-09-01',
        'end': '2026-09-30',
        'entries': [
          {'user_id': 7, 'date': '2026-09-09', 'status': 'remote'},
          {'user_id': 8, 'date': '2026-09-10', 'status': 'holiday'},
          {'user_id': 7, 'date': '2026-09-11', 'status': 'on_site'},
        ],
      }),
    );

    final result = await repo.getSchedule(
      start: '2026-09-01',
      end: '2026-09-30',
    );

    expect(adapter.lastOptions?.path, '/leave/schedule');
    expect(adapter.lastOptions?.method, 'GET');
    expect(adapter.lastOptions?.queryParameters['start'], '2026-09-01');
    expect(adapter.lastOptions?.queryParameters['end'], '2026-09-30');
    expect(result.isOk, isTrue);
    expect(result.data?.start, '2026-09-01');
    expect(result.data?.end, '2026-09-30');
    expect(result.data?.entries, hasLength(3));
    expect(result.data?.entries[0].userId, 7);
    expect(result.data?.entries[0].date, '2026-09-09');
    expect(result.data?.entries[0].status, PresenceStatus.remote);
    expect(result.data?.entries[1].status, PresenceStatus.holiday);
    expect(result.data?.entries[2].status, PresenceStatus.onSite);
  });

  test('declarePresence posts snake_case body and maps returned entries', () async {
    repo = makeRepo(
      (options, _) => _json(
        {
          'entries': [
            {'user_id': 7, 'date': '2026-09-09', 'status': 'remote'},
            {'user_id': 7, 'date': '2026-09-10', 'status': 'remote'},
          ],
        },
        status: 201,
      ),
    );

    final result = await repo.declarePresence(
      const NewPresence(
        startDate: '2026-09-09',
        endDate: '2026-09-10',
        status: DeclarableStatus.remote,
      ),
    );

    expect(adapter.lastOptions?.path, '/leave/presences');
    expect(adapter.lastOptions?.method, 'POST');
    expect(jsonDecode(adapter.lastBody), {
      'start_date': '2026-09-09',
      'end_date': '2026-09-10',
      'status': 'remote',
    });
    expect(result.isOk, isTrue);
    expect(result.data, hasLength(2));
    expect(result.data?.first.userId, 7);
    expect(result.data?.first.date, '2026-09-09');
    expect(result.data?.first.status, PresenceStatus.remote);
    expect(result.data?.last.date, '2026-09-10');
  });

  test('declarePresence omits end_date when it is not set', () async {
    repo = makeRepo(
      (options, _) => _json(
        {
          'entries': [
            {'user_id': 7, 'date': '2026-09-09', 'status': 'on_site'},
          ],
        },
        status: 201,
      ),
    );

    final result = await repo.declarePresence(
      const NewPresence(
        startDate: '2026-09-09',
        status: DeclarableStatus.onSite,
      ),
    );

    expect(jsonDecode(adapter.lastBody), {
      'start_date': '2026-09-09',
      'status': 'on_site',
    });
    expect(result.isOk, isTrue);
    expect(result.data?.single.status, PresenceStatus.onSite);
  });

  test('maps Dio 422 to ValidationFailure', () async {
    repo = makeRepo(
      (options, _) => _json(
        {'error': 'Dates invalides'},
        status: 422,
      ),
    );

    final result = await repo.declarePresence(
      const NewPresence(
        startDate: '2026-09-17',
        endDate: '2026-09-15',
        status: DeclarableStatus.remote,
      ),
    );

    expect(result.isOk, isFalse);
    expect(result.failure, isA<ValidationFailure>());
    expect((result.failure as ValidationFailure).message, 'Dates invalides');
  });
}
