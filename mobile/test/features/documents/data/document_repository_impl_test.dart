import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/features/documents/data/datasources/document_remote.dart';
import 'package:alize_mobile/features/documents/data/repositories/document_repository_impl.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
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

const _docJson = {
  'id': 21,
  'user_id': 7,
  'doc_type': 'work_certificate',
  'status': 'pending',
  'note': 'bank',
  'fields': {'employer': 'Alizé'},
  'issued_at': null,
  'decision_comment': null,
};

void main() {
  late _ScriptedAdapter adapter;

  DocumentRepositoryImpl makeRepo(
    ResponseBody Function(RequestOptions options, String body) onFetch,
  ) {
    adapter = _ScriptedAdapter(onFetch);
    final dio = Dio()..httpClientAdapter = adapter;
    return DocumentRepositoryImpl(remote: DocumentRemote(dio));
  }

  test('getRequests maps snake_case document JSON', () async {
    final repo = makeRepo((options, _) => _json([_docJson]));

    final result = await repo.getRequests();

    expect(adapter.lastOptions?.path, '/admin-docs/requests');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data, hasLength(1));
    final doc = result.data!.first;
    expect(doc.id, 21);
    expect(doc.userId, 7);
    expect(doc.docType, 'work_certificate');
    expect(doc.status, DocumentStatus.pending);
    expect(doc.note, 'bank');
    expect(doc.fields, {'employer': 'Alizé'});
  });

  test('getInbox calls /admin-docs/requests/inbox', () async {
    final repo = makeRepo(
      (options, _) => _json([
        {..._docJson, 'id': 22, 'status': 'processing'},
      ]),
    );

    final result = await repo.getInbox();

    expect(adapter.lastOptions?.path, '/admin-docs/requests/inbox');
    expect(result.isOk, isTrue);
    expect(result.data!.first.status, DocumentStatus.processing);
  });

  test('create posts snake_case body and maps the created request', () async {
    final repo = makeRepo((options, _) => _json(_docJson, status: 201));

    final result = await repo.create(
      const NewDocumentRequest(docType: 'work_certificate', note: 'bank'),
    );

    expect(adapter.lastOptions?.path, '/admin-docs/requests');
    expect(adapter.lastOptions?.method, 'POST');
    expect(jsonDecode(adapter.lastBody), {
      'doc_type': 'work_certificate',
      'note': 'bank',
    });
    expect(result.isOk, isTrue);
    expect(result.data?.id, 21);
    expect(result.data?.docType, 'work_certificate');
    expect(result.data?.status, DocumentStatus.pending);
    expect(result.data?.note, 'bank');
  });

  test('getRequest calls /admin-docs/requests/:id', () async {
    final repo = makeRepo(
      (options, _) => _json({..._docJson, 'status': 'ready'}),
    );

    final result = await repo.getRequest(21);

    expect(adapter.lastOptions?.path, '/admin-docs/requests/21');
    expect(adapter.lastOptions?.method, 'GET');
    expect(result.isOk, isTrue);
    expect(result.data?.id, 21);
    expect(result.data?.status, DocumentStatus.ready);
  });

  test('cancel patches /admin-docs/requests/:id/cancel', () async {
    final repo = makeRepo(
      (options, _) => _json({..._docJson, 'status': 'cancelled'}),
    );

    final result = await repo.cancel(21);

    expect(adapter.lastOptions?.path, '/admin-docs/requests/21/cancel');
    expect(adapter.lastOptions?.method, 'PATCH');
    expect(result.isOk, isTrue);
    expect(result.data?.status, DocumentStatus.cancelled);
  });

  test('update patches /admin-docs/requests/:id with fields and status',
      () async {
    final repo = makeRepo(
      (options, _) => _json({
        ..._docJson,
        'status': 'processing',
        'fields': {'employee_name': 'Ada'},
      }),
    );

    final result = await repo.update(
      21,
      fields: const {'employee_name': 'Ada'},
      status: 'processing',
      decisionComment: 'ok',
    );

    expect(adapter.lastOptions?.path, '/admin-docs/requests/21');
    expect(adapter.lastOptions?.method, 'PATCH');
    expect(jsonDecode(adapter.lastBody), {
      'fields': {'employee_name': 'Ada'},
      'status': 'processing',
      'decision_comment': 'ok',
    });
    expect(result.isOk, isTrue);
    expect(result.data?.status, DocumentStatus.processing);
    expect(result.data?.fields, {'employee_name': 'Ada'});
  });

  test('update omits null status and decision_comment', () async {
    final repo = makeRepo((options, _) => _json(_docJson));

    await repo.update(21, fields: const {'signer': 'RH'});

    expect(jsonDecode(adapter.lastBody), {
      'fields': {'signer': 'RH'},
    });
  });

  test('reject patches /admin-docs/requests/:id/reject', () async {
    final repo = makeRepo(
      (options, _) => _json({
        ..._docJson,
        'status': 'rejected',
        'decision_comment': 'no',
      }),
    );

    final result = await repo.reject(21, comment: 'no');

    expect(adapter.lastOptions?.path, '/admin-docs/requests/21/reject');
    expect(adapter.lastOptions?.method, 'PATCH');
    expect(jsonDecode(adapter.lastBody), {'comment': 'no'});
    expect(result.isOk, isTrue);
    expect(result.data?.status, DocumentStatus.rejected);
    expect(result.data?.decisionComment, 'no');
  });
}
