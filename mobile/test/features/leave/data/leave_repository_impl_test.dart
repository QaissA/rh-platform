import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/features/leave/data/datasources/leave_remote.dart';
import 'package:alize_mobile/features/leave/data/repositories/leave_repository_impl.dart';
import 'package:alize_mobile/features/leave/domain/entities/leave_status.dart';
import 'package:alize_mobile/features/leave/domain/entities/new_leave_request.dart';
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

const _requestJson = {
  'id': 11,
  'user_id': 7,
  'team_id': 3,
  'start_date': '2026-09-15',
  'end_date': '2026-09-17',
  'status': 'pending',
  'reason': 'paid',
  'days': 3,
  'decided_by': null,
  'decided_at': null,
  'decision_comment': null,
};

void main() {
  late Dio dio;
  late _ScriptedAdapter adapter;
  late LeaveRepositoryImpl repo;

  LeaveRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    dio = Dio()..httpClientAdapter = adapter;
    return LeaveRepositoryImpl(remote: LeaveRemote(dio));
  }

  test('getBalance maps snake_case JSON and numeric days_remaining', () async {
    repo = makeRepo(
      (options, _) => _json({'user_id': 7, 'days_remaining': 18}),
    );

    final result = await repo.getBalance();

    expect(adapter.lastOptions?.path, '/leave/balance');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data?.userId, 7);
    expect(result.data?.daysRemaining, 18);
  });

  test('getBalance maps string days_remaining to a number', () async {
    repo = makeRepo(
      (options, _) => _json({'user_id': 7, 'days_remaining': '18.5'}),
    );

    final result = await repo.getBalance();

    expect(result.isOk, isTrue);
    expect(result.data?.userId, 7);
    expect(result.data?.daysRemaining, 18.5);
  });

  test('getMyRequests maps snake_case list including pending_hr', () async {
    repo = makeRepo(
      (options, _) => _json([
        _requestJson,
        {
          ..._requestJson,
          'id': 12,
          'status': 'pending_hr',
          'reason': null,
          'team_id': null,
          'days': 2,
          'decided_by': 4,
          'decided_at': '2026-09-08T10:00:00Z',
          'decision_comment': 'ok',
        },
      ]),
    );

    final result = await repo.getMyRequests();

    expect(adapter.lastOptions?.path, '/leave/requests');
    expect(result.isOk, isTrue);
    expect(result.data, hasLength(2));
    final first = result.data!.first;
    expect(first.id, 11);
    expect(first.userId, 7);
    expect(first.teamId, 3);
    expect(first.startDate, '2026-09-15');
    expect(first.endDate, '2026-09-17');
    expect(first.status, LeaveStatus.pending);
    expect(first.reason, 'paid');
    expect(first.days, 3);
    expect(first.decidedBy, isNull);
    expect(first.decidedAt, isNull);
    expect(first.decisionComment, isNull);

    final second = result.data!.last;
    expect(second.status, LeaveStatus.pendingHr);
    expect(second.reason, isNull);
    expect(second.teamId, isNull);
    expect(second.decidedBy, 4);
    expect(second.decidedAt, '2026-09-08T10:00:00Z');
    expect(second.decisionComment, 'ok');
  });

  test('create posts snake_case body and maps the created request', () async {
    repo = makeRepo((options, _) => _json(_requestJson, status: 201));

    final result = await repo.create(
      const NewLeaveRequest(
        startDate: '2026-09-15',
        endDate: '2026-09-17',
        reason: 'paid',
      ),
    );

    expect(adapter.lastOptions?.path, '/leave/requests');
    expect(adapter.lastOptions?.method, 'POST');
    expect(jsonDecode(adapter.lastBody), {
      'start_date': '2026-09-15',
      'end_date': '2026-09-17',
      'reason': 'paid',
    });
    expect(result.isOk, isTrue);
    expect(result.data?.id, 11);
    expect(result.data?.status, LeaveStatus.pending);
  });

  test('getTeamRequests sends comma-separated status query', () async {
    repo = makeRepo((options, _) => _json([_requestJson]));

    final result = await repo.getTeamRequests(
      status: const [LeaveStatus.pending, LeaveStatus.pendingHr],
    );

    expect(adapter.lastOptions?.path, '/leave/requests/team');
    expect(
      adapter.lastOptions?.queryParameters['status'],
      'pending,pending_hr',
    );
    expect(result.isOk, isTrue);
    expect(result.data?.single.id, 11);
  });

  test('approve and reject hit member PATCH paths', () async {
    repo = makeRepo(
      (options, _) => _json({..._requestJson, 'status': 'pending_hr'}),
    );

    final approved = await repo.approve(11);
    expect(adapter.lastOptions?.path, '/leave/requests/11/approve');
    expect(adapter.lastOptions?.method, 'PATCH');
    expect(approved.data?.status, LeaveStatus.pendingHr);

    final rejected = await repo.reject(11, comment: 'too soon');
    expect(adapter.lastOptions?.path, '/leave/requests/11/reject');
    expect(jsonDecode(adapter.lastBody), {'comment': 'too soon'});
    expect(rejected.isOk, isTrue);
  });

  test('maps Dio 422 to ValidationFailure', () async {
    repo = makeRepo(
      (options, _) => _json(
        {
          'errors': ['end_date must be on or after start_date'],
        },
        status: 422,
      ),
    );

    final result = await repo.create(
      const NewLeaveRequest(
        startDate: '2026-09-17',
        endDate: '2026-09-15',
      ),
    );

    expect(result.isOk, isFalse);
    expect(result.failure, isA<ValidationFailure>());
    expect(
      (result.failure as ValidationFailure).message,
      'end_date must be on or after start_date',
    );
  });
}
