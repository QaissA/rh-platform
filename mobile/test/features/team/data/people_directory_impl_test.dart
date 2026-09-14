import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/team/data/datasources/team_remote.dart';
import 'package:alize_mobile/features/team/data/datasources/users_remote.dart';
import 'package:alize_mobile/features/team/data/repositories/people_directory_impl.dart';
import 'package:alize_mobile/features/team/data/repositories/team_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.onFetch);

  final ResponseBody Function(RequestOptions options, String body) onFetch;

  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    return onFetch(options, '');
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

  PeopleDirectoryImpl makeDirectory({
    required String role,
    required ResponseBody Function(RequestOptions options, String body) onFetch,
  }) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return PeopleDirectoryImpl(
      teamRepository: TeamRepositoryImpl(remote: TeamRemote(dio)),
      usersRemote: UsersRemote(dio),
      currentUser: () => User(
        id: 1,
        email: 'ada@rh.local',
        role: role,
        firstName: 'Ada',
        lastName: 'Lovelace',
        jobTitle: 'Dev',
      ),
      collaboratorName: (id) => 'Collaborateur #$id',
    );
  }

  test('falls back when the directory has no match', () {
    final directory = makeDirectory(
      role: 'employee',
      onFetch: (options, _) => _json({'team': null, 'members': <dynamic>[]}),
    );

    expect(directory.nameOf(42), 'Collaborateur #42');
    expect(directory.initialsOf(42), '?');
    expect(directory.jobTitleOf(42), isNull);
  });

  test('rh and admin load GET /auth/users', () async {
    final directory = makeDirectory(
      role: 'rh',
      onFetch: (options, _) => _json([
        {
          'id': 9,
          'email': 'alan@rh.local',
          'role': 'employee',
          'first_name': 'Alan',
          'last_name': 'Turing',
          'job_title': 'Dev',
          'pending_job_title': 'Lead',
        },
      ]),
    );

    final result = await directory.load();

    expect(adapter.lastOptions?.path, '/auth/users');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(directory.nameOf(9), 'Alan Turing');
    expect(directory.jobTitleOf(9), 'Dev');
    expect(directory.initialsOf(9), 'AT');
    expect(directory.get(9)?.pendingJobTitle, 'Lead');
  });

  test('admin also loads GET /auth/users', () async {
    final directory = makeDirectory(
      role: 'admin',
      onFetch: (options, _) => _json(<dynamic>[]),
    );

    await directory.load();

    expect(adapter.lastOptions?.path, '/auth/users');
  });

  test('others load teams/mine and include self', () async {
    final directory = makeDirectory(
      role: 'employee',
      onFetch: (options, _) => _json({
        'team': {'id': 3, 'name': 'Plateforme'},
        'members': [
          {
            'id': 8,
            'email': 'alan@rh.local',
            'first_name': 'Alan',
            'last_name': 'Turing',
            'role': 'employee',
            'job_title': null,
          },
        ],
      }),
    );

    final result = await directory.load();

    expect(adapter.lastOptions?.path, '/auth/teams/mine');
    expect(result.isOk, isTrue);
    expect(directory.nameOf(1), 'Ada Lovelace');
    expect(directory.nameOf(8), 'Alan Turing');
    expect(directory.jobTitleOf(1), 'Dev');
  });
}
