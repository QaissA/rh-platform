import 'package:alize_mobile/features/documents/data/models/document_request_dto.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:dio/dio.dart';

class DocumentRemote {
  DocumentRemote(this._dio);

  final Dio _dio;

  Future<List<DocumentRequestDto>> getRequests() async {
    final response = await _dio.get<List<dynamic>>('/admin-docs/requests');
    return _list(response.data);
  }

  Future<List<DocumentRequestDto>> getInbox({String? status}) async {
    final response = await _dio.get<List<dynamic>>(
      '/admin-docs/requests/inbox',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return _list(response.data);
  }

  Future<DocumentRequestDto> create(NewDocumentRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/admin-docs/requests',
      data: {
        'doc_type': request.docType,
        'note': ?request.note,
      },
    );
    return DocumentRequestDto.fromJson(response.data!);
  }

  Future<DocumentRequestDto> getRequest(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin-docs/requests/$id',
    );
    return DocumentRequestDto.fromJson(response.data!);
  }

  Future<DocumentRequestDto> cancel(int id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin-docs/requests/$id/cancel',
      data: <String, dynamic>{},
    );
    return DocumentRequestDto.fromJson(response.data!);
  }

  Future<DocumentRequestDto> update(
    int id, {
    Map<String, String>? fields,
    String? status,
    String? decisionComment,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin-docs/requests/$id',
      data: {
        'fields': ?fields,
        'status': ?status,
        'decision_comment': ?decisionComment,
      },
    );
    return DocumentRequestDto.fromJson(response.data!);
  }

  Future<DocumentRequestDto> reject(int id, {String? comment}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admin-docs/requests/$id/reject',
      data: {
        'comment': ?comment,
      },
    );
    return DocumentRequestDto.fromJson(response.data!);
  }

  List<DocumentRequestDto> _list(List<dynamic>? data) {
    return (data ?? const [])
        .map(
          (e) => DocumentRequestDto.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}
