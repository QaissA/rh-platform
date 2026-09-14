import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/documents/data/datasources/document_remote.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:alize_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:dio/dio.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  DocumentRepositoryImpl({required DocumentRemote remote}) : _remote = remote;

  final DocumentRemote _remote;

  @override
  Future<Result<List<DocumentRequest>>> getRequests() => _guard(
        () async =>
            (await _remote.getRequests()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<List<DocumentRequest>>> getInbox({String? status}) => _guard(
        () async => (await _remote.getInbox(status: status))
            .map((e) => e.toDomain())
            .toList(),
      );

  @override
  Future<Result<DocumentRequest>> create(NewDocumentRequest request) => _guard(
        () async => (await _remote.create(request)).toDomain(),
      );

  @override
  Future<Result<DocumentRequest>> getRequest(int id) => _guard(
        () async => (await _remote.getRequest(id)).toDomain(),
      );

  @override
  Future<Result<DocumentRequest>> cancel(int id) => _guard(
        () async => (await _remote.cancel(id)).toDomain(),
      );

  @override
  Future<Result<DocumentRequest>> update(
    int id, {
    Map<String, String>? fields,
    String? status,
    String? decisionComment,
  }) =>
      _guard(
        () async => (await _remote.update(
          id,
          fields: fields,
          status: status,
          decisionComment: decisionComment,
        ))
            .toDomain(),
      );

  @override
  Future<Result<DocumentRequest>> reject(int id, {String? comment}) => _guard(
        () async => (await _remote.reject(id, comment: comment)).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
