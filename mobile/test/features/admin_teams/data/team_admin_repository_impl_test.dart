import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/features/admin_teams/data/datasources/team_admin_remote.dart';
import 'package:alize_mobile/features/admin_teams/data/repositories/team_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/new_team.dart';
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

const _teamJson = {
  'id': 2,
  'name': 'Core',
  'project_id': 9,
  'project': {'id': 9, 'name': 'Atlas'},
  'business_unit': {'id': 3, 'name': 'Engineering'},
  'member_count': 6,
};

void main() {
  late _ScriptedAdapter adapter;

  TeamAdminRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return TeamAdminRepositoryImpl(remote: TeamAdminRemote(dio));
  }

  test('list hits GET /auth/teams and maps name', () async {
    final repo = makeRepo((options, _) => _json([_teamJson]));

    final result = await repo.list();

    expect(adapter.lastOptions?.path, '/auth/teams');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data!.first.name, 'Core');
    expect(result.data!.first.projectId, 9);
  });

  test('create posts name and project_id', () async {
    final repo = makeRepo((options, _) => _json(_teamJson));

    final result = await repo.create(
      const NewTeam(name: 'Core', projectId: 9),
    );

    expect(adapter.lastOptions?.path, '/auth/teams');
    expect(adapter.lastOptions?.method, 'POST');
    final body = jsonDecode(adapter.lastBody) as Map<String, dynamic>;
    expect(body.keys, containsAll(['name', 'project_id']));
    expect(body['name'], 'Core');
    expect(body['project_id'], 9);
    expect(result.isOk, isTrue);
    expect(result.data?.name, 'Core');
  });
}
