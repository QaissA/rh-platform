import 'package:alize_mobile/features/chat/data/models/chat_message_dto.dart';
import 'package:alize_mobile/features/chat/data/models/conversation_dto.dart';
import 'package:alize_mobile/features/chat/domain/entities/chat_upload.dart';
import 'package:alize_mobile/features/team/data/models/team_member_dto.dart';
import 'package:dio/dio.dart';

class ChatRemote {
  ChatRemote(this._dio);

  final Dio _dio;

  Future<List<ConversationDto>> list() async {
    final response = await _dio.get<List<dynamic>>('/auth/conversations');
    return _conversations(response.data);
  }

  Future<List<TeamMemberDto>> directory() async {
    final response = await _dio.get<List<dynamic>>('/auth/directory');
    return (response.data ?? const [])
        .map(
          (e) => TeamMemberDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<ConversationDto> open(int userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/conversations',
      data: {'user_id': userId},
    );
    return ConversationDto.fromJson(response.data!);
  }

  Future<List<ChatMessageDto>> history(int conversationId) async {
    final response = await _dio.get<List<dynamic>>(
      '/auth/conversations/$conversationId/messages',
    );
    return _messages(response.data);
  }

  Future<ChatMessageDto> send(
    int conversationId, {
    String body = '',
    ChatUpload? file,
  }) async {
    final path = '/auth/conversations/$conversationId/messages';
    if (file != null) {
      final form = FormData.fromMap({
        if (body.trim().isNotEmpty) 'body': body.trim(),
        'file': MultipartFile.fromBytes(
          file.bytes,
          filename: file.filename,
          contentType: DioMediaType.parse(file.contentType),
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(path, data: form);
      return ChatMessageDto.fromJson(response.data!);
    }

    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {'body': body},
    );
    return ChatMessageDto.fromJson(response.data!);
  }

  Future<ConversationDto> markRead(int conversationId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/conversations/$conversationId/read',
      data: <String, dynamic>{},
    );
    return ConversationDto.fromJson(response.data!);
  }

  Future<List<int>> fileBytes(String url) async {
    final response = await _dio.get<List<int>>(
      authFilePath(url),
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }

  static String authFilePath(String url) {
    if (url.startsWith('/auth')) return url;
    return '/auth$url';
  }

  List<ConversationDto> _conversations(List<dynamic>? data) {
    return (data ?? const [])
        .map(
          (e) => ConversationDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  List<ChatMessageDto> _messages(List<dynamic>? data) {
    return (data ?? const [])
        .map(
          (e) => ChatMessageDto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }
}
