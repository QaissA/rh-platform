import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/features/dossiers/data/datasources/dossier_remote.dart';
import 'package:alize_mobile/features/dossiers/data/repositories/dossier_repository_impl.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/update_dossier.dart';
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

const _dossierJson = {
  'id': 7,
  'email': 'ada@rh.local',
  'role': 'employee',
  'team_id': 2,
  'business_unit_id': 3,
  'project_id': 4,
  'first_name': 'Ada',
  'last_name': 'Lovelace',
  'job_title': 'Engineer',
  'pending_job_title': 'Staff Engineer',
  'must_change_password': false,
  'address_line': '12 rue X',
  'postal_code': '75001',
  'city': 'Paris',
  'country': 'FR',
  'signature_png': 'data:image/png;base64,abc',
  'signature_locked': true,
  'salary_cents': 320000,
  'contract_type': 'cdi',
  'hired_on': '2024-03-01',
  'iban': 'FR7630006000011234567890189',
};

void main() {
  late _ScriptedAdapter adapter;

  DossierRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return DossierRepositoryImpl(remote: DossierRemote(dio));
  }

  test('getDossier maps salary_cents from JSON', () async {
    final repo = makeRepo((options, _) => _json(_dossierJson));

    final result = await repo.getDossier(7);

    expect(adapter.lastOptions?.path, '/auth/users/7');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    final dossier = result.data!;
    expect(dossier.salaryCents, _dossierJson['salary_cents']);
    expect(dossier.contractType, 'cdi');
    expect(dossier.hiredOn, '2024-03-01');
    expect(dossier.iban, _dossierJson['iban']);
    expect(dossier.profile.id, 7);
    expect(dossier.profile.firstName, 'Ada');
    expect(dossier.profile.lastName, 'Lovelace');
    expect(dossier.profile.jobTitle, 'Engineer');
    expect(dossier.profile.pendingJobTitle, 'Staff Engineer');
    expect(dossier.profile.addressLine, '12 rue X');
    expect(dossier.profile.signatureLocked, isTrue);
  });

  test('updateDossier patches salary_cents in the request body', () async {
    final repo = makeRepo((options, _) => _json(_dossierJson));
    const payload = UpdateDossier(
      firstName: 'Ada',
      lastName: 'Lovelace',
      jobTitle: 'Engineer',
      addressLine: '12 rue X',
      postalCode: '75001',
      city: 'Paris',
      country: 'FR',
      salaryCents: 320000,
      contractType: 'cdi',
      hiredOn: '2024-03-01',
      iban: 'FR7630006000011234567890189',
    );

    final result = await repo.updateDossier(7, payload);

    expect(adapter.lastOptions?.path, '/auth/users/7');
    expect(adapter.lastOptions?.method, 'PATCH');
    final body = jsonDecode(adapter.lastBody) as Map<String, dynamic>;
    expect(body['salary_cents'], payload.salaryCents);
    expect(body['contract_type'], 'cdi');
    expect(body['hired_on'], '2024-03-01');
    expect(body['iban'], payload.iban);
    expect(body['first_name'], 'Ada');
    expect(body['job_title'], 'Engineer');
    expect(result.isOk, isTrue);
    expect(result.data?.salaryCents, payload.salaryCents);
  });

  test('acceptJobTitle posts to job-title/accept', () async {
    final repo = makeRepo(
      (options, _) => _json({
        ..._dossierJson,
        'job_title': 'Staff Engineer',
        'pending_job_title': null,
      }),
    );

    final result = await repo.acceptJobTitle(7);

    expect(adapter.lastOptions?.path, '/auth/users/7/job-title/accept');
    expect(adapter.lastOptions?.method, 'POST');
    expect(result.isOk, isTrue);
    expect(result.data?.profile.jobTitle, 'Staff Engineer');
    expect(result.data?.profile.pendingJobTitle, isNull);
  });

  test('rejectJobTitle posts optional comment', () async {
    final repo = makeRepo(
      (options, _) => _json({
        ..._dossierJson,
        'pending_job_title': null,
      }),
    );

    final result = await repo.rejectJobTitle(7, comment: 'no');

    expect(adapter.lastOptions?.path, '/auth/users/7/job-title/reject');
    expect(adapter.lastOptions?.method, 'POST');
    expect(jsonDecode(adapter.lastBody), {'comment': 'no'});
    expect(result.isOk, isTrue);
    expect(result.data?.profile.pendingJobTitle, isNull);
  });

  test('unlockSignature posts to signature/unlock', () async {
    final repo = makeRepo(
      (options, _) => _json({
        ..._dossierJson,
        'signature_locked': false,
      }),
    );

    final result = await repo.unlockSignature(7);

    expect(adapter.lastOptions?.path, '/auth/users/7/signature/unlock');
    expect(adapter.lastOptions?.method, 'POST');
    expect(result.isOk, isTrue);
    expect(result.data?.profile.signatureLocked, isFalse);
  });
}
