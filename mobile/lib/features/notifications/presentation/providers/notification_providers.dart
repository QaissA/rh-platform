import 'dart:async';

import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/notifications/data/datasources/notification_remote.dart';
import 'package:alize_mobile/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:alize_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:alize_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRemoteProvider = Provider<NotificationRemote>(
  (ref) => NotificationRemote(ref.watch(dioProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepositoryImpl(
    remote: ref.watch(notificationRemoteProvider),
  ),
);

class NotificationsState {
  const NotificationsState({this.items = const []});

  final List<AppNotification> items;

  int get unreadCount => items.where((n) => !n.read).length;
}

final notificationsControllerProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);

class NotificationsController extends Notifier<NotificationsState> {
  bool _disposed = false;

  @override
  NotificationsState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthSignedOut) {
        state = const NotificationsState();
      }
    });
    return const NotificationsState();
  }

  Future<void> load() async {
    if (ref.read(authProvider) is AuthSignedOut) return;
    final result = await ref.read(notificationRepositoryProvider).list();
    if (_disposed || ref.read(authProvider) is AuthSignedOut) return;
    if (result.isOk && result.data != null) {
      state = NotificationsState(items: result.data!);
    }
  }

  Future<void> markRead(int id) async {
    final result = await ref.read(notificationRepositoryProvider).markRead(id);
    if (_disposed) return;
    final updated = result.data;
    if (!result.isOk || updated == null) return;
    state = NotificationsState(
      items: [
        for (final item in state.items)
          if (item.id == updated.id) updated else item,
      ],
    );
  }
}
