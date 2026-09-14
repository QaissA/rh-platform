import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/features/admin_projects/data/datasources/project_admin_remote.dart';
import 'package:alize_mobile/features/admin_projects/data/repositories/project_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/new_project.dart';
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

const _projectJson = {
  'id': 9,
  'name': 'Atlas',
  'business_unit_id': 3,
  'business_unit': {'id': 3, 'name': 'Engineering'},
  'lead_id': 5,
  'lead': {
    'id': 5,
    'email': 'lead@rh.local',
    'first_name': 'Lee',
    'last_name': 'Lead',
    'role': 'lead',
  },
  'member_count': 4,
};

void main() {
  late _ScriptedAdapter adapter;

  ProjectAdminRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return ProjectAdminRepositoryImpl(remote: ProjectAdminRemote(dio));
  }

  test('list hits GET /auth/projects and maps name', () async {
    final repo = makeRepo((options, _) => _json([_projectJson]));

    final result = await repo.list(businessUnitId: 3);

    expect(adapter.lastOptions?.path, '/auth/projects');
    expect(adapter.lastOptions?.method, 'GET');
    expect(
      adapter.lastOptions?.queryParameters['business_unit_id'],
      3,
    );
    expect(result.isOk, isTrue);
    expect(result.data!.first.name, 'Atlas');
    expect(result.data!.first.businessUnitId, 3);
  });

  test('create posts name, business_unit_id, and lead_id', () async {
    final repo = makeRepo((options, _) => _json(_projectJson));

    final result = await repo.create(
      const NewProject(name: 'Atlas', businessUnitId: 3, leadId: 5),
    );

    expect(adapter.lastOptions?.path, '/auth/projects');
    expect(adapter.lastOptions?.method, 'POST');
    final body = jsonDecode(adapter.lastBody) as Map<String, dynamic>;
    expect(body.keys, containsAll(['name', 'business_unit_id', 'lead_id']));
    expect(body['name'], 'Atlas');
    expect(body['business_unit_id'], 3);
    expect(body['lead_id'], 5);
    expect(result.isOk, isTrue);
    expect(result.data?.name, 'Atlas');
  });
}
