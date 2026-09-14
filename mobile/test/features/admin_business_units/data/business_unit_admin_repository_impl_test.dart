import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/features/admin_business_units/data/datasources/business_unit_admin_remote.dart';
import 'package:alize_mobile/features/admin_business_units/data/repositories/business_unit_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/new_business_unit.dart';
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

const _unitJson = {
  'id': 3,
  'name': 'Engineering',
  'manager_id': 4,
  'manager': {
    'id': 4,
    'email': 'mgr@rh.local',
    'first_name': 'Pat',
    'last_name': 'Manager',
    'role': 'manager',
  },
  'project_count': 2,
  'member_count': 8,
};

void main() {
  late _ScriptedAdapter adapter;

  BusinessUnitAdminRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return BusinessUnitAdminRepositoryImpl(
      remote: BusinessUnitAdminRemote(dio),
    );
  }

  test('list hits GET /auth/business-units and maps name', () async {
    final repo = makeRepo((options, _) => _json([_unitJson]));

    final result = await repo.list();

    expect(adapter.lastOptions?.path, '/auth/business-units');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data, hasLength(1));
    expect(result.data!.first.name, 'Engineering');
    expect(result.data!.first.managerId, 4);
  });

  test('create posts name and manager_id', () async {
    final repo = makeRepo((options, _) => _json(_unitJson));

    final result = await repo.create(
      const NewBusinessUnit(name: 'Engineering', managerId: 4),
    );

    expect(adapter.lastOptions?.path, '/auth/business-units');
    expect(adapter.lastOptions?.method, 'POST');
    final body = jsonDecode(adapter.lastBody) as Map<String, dynamic>;
    expect(body.keys, containsAll(['name', 'manager_id']));
    expect(body['name'], 'Engineering');
    expect(body['manager_id'], 4);
    expect(result.isOk, isTrue);
    expect(result.data?.name, 'Engineering');
  });
}
