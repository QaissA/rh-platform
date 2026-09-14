import '../../domain/entities/document_request.dart';
import '../../domain/entities/document_status.dart';

class DocumentRequestDto {
  const DocumentRequestDto({
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
  final String status;
  final String? note;
  final Map<String, String>? fields;
  final String? issuedAt;
  final String? decisionComment;

  factory DocumentRequestDto.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    return DocumentRequestDto(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      docType: json['doc_type'] as String,
      status: json['status'] as String,
      note: json['note'] as String?,
      fields: rawFields is Map
          ? rawFields.map((key, value) => MapEntry('$key', '$value'))
          : null,
      issuedAt: json['issued_at'] as String?,
      decisionComment: json['decision_comment'] as String?,
    );
  }

  DocumentRequest toDomain() => DocumentRequest(
        id: id,
        userId: userId,
        docType: docType,
        status: DocumentStatus.fromWire(status),
        note: note,
        fields: fields,
        issuedAt: issuedAt,
        decisionComment: decisionComment,
      );
}
