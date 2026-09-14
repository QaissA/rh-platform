import '../../../../core/error/result.dart';
import '../entities/document_request.dart';
import '../entities/new_document_request.dart';

abstract class DocumentRepository {
  Future<Result<List<DocumentRequest>>> getRequests();

  Future<Result<List<DocumentRequest>>> getInbox({String? status});

  Future<Result<DocumentRequest>> create(NewDocumentRequest request);

  Future<Result<DocumentRequest>> getRequest(int id);

  Future<Result<DocumentRequest>> cancel(int id);

  Future<Result<DocumentRequest>> update(
    int id, {
    Map<String, String>? fields,
    String? status,
    String? decisionComment,
  });

  Future<Result<DocumentRequest>> reject(int id, {String? comment});
}
