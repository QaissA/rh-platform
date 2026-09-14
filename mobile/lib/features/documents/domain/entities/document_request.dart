import 'document_status.dart';

class DocumentRequest {
  const DocumentRequest({
    required this.id,
    required this.userId,
    required this.docType,
    required this.status,
    this.note,
    this.fields,
    this.issuedAt,
    this.decisionComment,
  });

  final int id;
  final int userId;
  final String docType;
  final DocumentStatus status;
  final String? note;
  final Map<String, String>? fields;
  final String? issuedAt;
  final String? decisionComment;
}
