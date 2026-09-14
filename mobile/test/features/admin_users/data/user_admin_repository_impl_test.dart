import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/features/admin_users/data/datasources/user_admin_remote.dart';
import 'package:alize_mobile/features/admin_users/data/repositories/user_admin_repository_impl.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/new_user.dart';
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

const _userJson = {
  'id': 7,
  'email': 'ada@rh.local',
  'role': 'employee',
  'team_id': 2,
  'business_unit_id': 3,
  'project_id': 9,
  'first_name': 'Ada',
  'last_name': 'Lovelace',
};

void main() {
  late _ScriptedAdapter adapter;

  UserAdminRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return UserAdminRepositoryImpl(remote: UserAdminRemote(dio));
  }

  test('list hits GET /auth/users and maps email', () async {
    final repo = makeRepo((options, _) => _json([_userJson]));

    final result = await repo.list();

    expect(adapter.lastOptions?.path, '/auth/users');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data!.first.email, 'ada@rh.local');
  });

  test('create posts NewUser body keys and maps temporary_password', () async {
    final repo = makeRepo(
      (options, _) => _json({
        ..._userJson,
        'temporary_password': 'Once-Only-8',
      }),
    );

    final result = await repo.create(
      const NewUser(
        email: 'ada@rh.local',
        firstName: 'Ada',
        lastName: 'Lovelace',
        role: 'employee',
        teamId: 2,
        businessUnitId: 3,
        projectId: 9,
      ),
    );

    expect(adapter.lastOptions?.path, '/auth/users');
    expect(adapter.lastOptions?.method, 'POST');
    final body = jsonDecode(adapter.lastBody) as Map<String, dynamic>;
    expect(
      body.keys,
      containsAll([
        'email',
        'first_name',
        'last_name',
        'role',
        'team_id',
        'business_unit_id',
        'project_id',
      ]),
    );
    expect(body['email'], 'ada@rh.local');
    expect(body['role'], 'employee');
    expect(result.isOk, isTrue);
    expect(result.data?.user.email, 'ada@rh.local');
    expect(result.data?.temporaryPassword, 'Once-Only-8');
  });
}
