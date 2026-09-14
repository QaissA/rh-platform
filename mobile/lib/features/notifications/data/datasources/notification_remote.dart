import 'package:alize_mobile/features/notifications/data/models/app_notification_dto.dart';
import 'package:dio/dio.dart';

class NotificationRemote {
  NotificationRemote(this._dio);

  final Dio _dio;

  Future<List<AppNotificationDto>> list() async {
    final response = await _dio.get<List<dynamic>>('/auth/notifications');
    return _list(response.data);
  }

  Future<AppNotificationDto> markRead(int id) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/auth/notifications/$id/read',
      data: <String, dynamic>{},
    );
    return AppNotificationDto.fromJson(response.data!);
  }

  List<AppNotificationDto> _list(List<dynamic>? data) {
    return (data ?? const [])
        .map(
          (e) => AppNotificationDto.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}
