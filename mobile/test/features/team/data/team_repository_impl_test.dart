import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/features/team/data/datasources/team_remote.dart';
import 'package:alize_mobile/features/team/data/repositories/team_repository_impl.dart';
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
  late TeamRepositoryImpl repo;

  TeamRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return TeamRepositoryImpl(remote: TeamRemote(dio));
  }

  test('getMine maps snake_case team and members', () async {
    repo = makeRepo(
      (options, _) => _json({
        'team': {'id': 3, 'name': 'Plateforme'},
        'members': [
          {
            'id': 8,
            'email': 'alan@rh.local',
            'first_name': 'Alan',
            'last_name': 'Turing',
            'role': 'employee',
            'job_title': 'Dev',
          },
        ],
      }),
    );

    final result = await repo.getMine();

    expect(adapter.lastOptions?.path, '/auth/teams/mine');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data?.team?.id, 3);
    expect(result.data?.team?.name, 'Plateforme');
    expect(result.data?.members, hasLength(1));
    final member = result.data!.members.single;
    expect(member.id, 8);
    expect(member.email, 'alan@rh.local');
    expect(member.firstName, 'Alan');
    expect(member.lastName, 'Turing');
    expect(member.role, 'employee');
    expect(member.jobTitle, 'Dev');
  });

  test('getMine maps a null team to an empty roster', () async {
    repo = makeRepo(
      (options, _) => _json({'team': null, 'members': <dynamic>[]}),
    );

    final result = await repo.getMine();

    expect(result.isOk, isTrue);
    expect(result.data?.team, isNull);
    expect(result.data?.members, isEmpty);
  });

  test('maps Dio 422 to ValidationFailure', () async {
    repo = makeRepo(
      (options, _) => _json(
        {
          'errors': ['team unavailable'],
        },
        status: 422,
      ),
    );

    final result = await repo.getMine();

    expect(result.isOk, isFalse);
    expect(result.failure, isA<ValidationFailure>());
    expect((result.failure as ValidationFailure).message, 'team unavailable');
  });
}
