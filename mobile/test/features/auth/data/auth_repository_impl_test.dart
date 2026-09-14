import 'dart:convert';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/features/auth/data/datasources/auth_remote.dart';
import 'package:alize_mobile/features/auth/data/models/user_dto.dart';
import 'package:alize_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemote extends Mock implements AuthRemote {}

void main() {
  late MockAuthRemote remote;
  late MemorySessionStore store;
  late AuthRepositoryImpl repo;

  final userJson = <String, dynamic>{
    'id': 1,
    'email': 'a@b.com',
    'role': 'employee',
    'team_id': 2,
    'business_unit_id': 3,
    'project_id': 4,
    'first_name': 'Ada',
    'last_name': 'Lovelace',
    'job_title': 'Engineer',
    'pending_job_title': null,
    'must_change_password': false,
  };

  late UserDto dto;

  DioException unauthorized({required String path}) {
    final options = RequestOptions(path: path);
    return DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 401,
      ),
    );
  }

  setUp(() {
    remote = MockAuthRemote();
    store = MemorySessionStore();
    repo = AuthRepositoryImpl(remote: remote, sessionStore: store);
    dto = UserDto.fromJson(userJson);
  });

  test('login success returns Session and saves token plus user json', () async {
    when(
      () => remote.login(email: 'a@b.com', password: 'secret'),
    ).thenAnswer((_) async => (token: 'jwt', user: dto));

    final result = await repo.login(email: 'a@b.com', password: 'secret');

    expect(result.isOk, isTrue);
    expect(result.data?.token, 'jwt');
    expectUser(result.data!.user, dto.toDomain());
    expect(await store.readToken(), 'jwt');
    final stored = jsonDecode(await store.readUserJson() as String) as Map<String, dynamic>;
    expect(stored['first_name'], 'Ada');
    expect(stored['must_change_password'], isFalse);
    expect(stored['team_id'], 2);
    expect(stored['business_unit_id'], 3);
    expect(stored['project_id'], 4);
    expect(stored['pending_job_title'], isNull);
    expect(stored['job_title'], 'Engineer');
    expect(stored['last_name'], 'Lovelace');
    expect(stored.containsKey('firstName'), isFalse);
  });

  test('login Dio 401 returns UnauthorizedFailure and leaves store empty', () async {
    when(
      () => remote.login(email: 'a@b.com', password: 'secret'),
    ).thenThrow(unauthorized(path: '/auth/login'));

    final result = await repo.login(email: 'a@b.com', password: 'secret');

    expect(result.isOk, isFalse);
    expect(result.failure, isA<UnauthorizedFailure>());
    expect(await store.readToken(), isNull);
    expect(await store.readUserJson(), isNull);
  });

  test('me unauthorized clears the session store', () async {
    await store.save(token: 'jwt', userJson: jsonEncode(userJson));
    when(() => remote.me()).thenThrow(unauthorized(path: '/auth/me'));

    final result = await repo.me();

    expect(result.isOk, isFalse);
    expect(result.failure, isA<UnauthorizedFailure>());
    expect(await store.readToken(), isNull);
    expect(await store.readUserJson(), isNull);
  });
}

void expectUser(User actual, User expected) {
  expect(actual.id, expected.id);
  expect(actual.email, expected.email);
  expect(actual.role, expected.role);
  expect(actual.teamId, expected.teamId);
  expect(actual.businessUnitId, expected.businessUnitId);
  expect(actual.projectId, expected.projectId);
  expect(actual.firstName, expected.firstName);
  expect(actual.lastName, expected.lastName);
  expect(actual.jobTitle, expected.jobTitle);
  expect(actual.pendingJobTitle, expected.pendingJobTitle);
  expect(actual.mustChangePassword, expected.mustChangePassword);
}
