import '../../domain/entities/app_notification.dart';

class AppNotificationDto {
  const AppNotificationDto({
    required this.id,
    required this.kind,
    required this.title,
    required this.read,
    required this.createdAt,
    this.body,
    this.link,
  });

  final int id;
  final String kind;
  final String title;
  final String? body;
  final String? link;
  final bool read;
  final String createdAt;

  factory AppNotificationDto.fromJson(Map<String, dynamic> json) {
    return AppNotificationDto(
      id: json['id'] as int,
      kind: json['kind'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      link: json['link'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }

  AppNotification toDomain() => AppNotification(
        id: id,
        kind: kind,
        title: title,
        body: body,
        link: link,
        read: read,
        createdAt: createdAt,
      );
}
