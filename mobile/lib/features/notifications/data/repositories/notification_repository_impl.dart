import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/network/error_mapper.dart';
import 'package:alize_mobile/features/notifications/data/datasources/notification_remote.dart';
import 'package:alize_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:alize_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:dio/dio.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required NotificationRemote remote})
      : _remote = remote;

  final NotificationRemote _remote;

  @override
  Future<Result<List<AppNotification>>> list() => _guard(
        () async => (await _remote.list()).map((e) => e.toDomain()).toList(),
      );

  @override
  Future<Result<AppNotification>> markRead(int id) => _guard(
        () async => (await _remote.markRead(id)).toDomain(),
      );

  Future<Result<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Result.ok(await run());
    } on DioException catch (e) {
      return Result.err(mapDio(e));
    }
  }
}
