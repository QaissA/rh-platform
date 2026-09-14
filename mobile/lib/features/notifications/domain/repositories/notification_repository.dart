import '../../../../core/error/result.dart';
import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Future<Result<List<AppNotification>>> list();

  Future<Result<AppNotification>> markRead(int id);
}
