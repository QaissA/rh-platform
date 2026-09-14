import 'dart:async';

import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:alize_mobile/features/notifications/domain/notification_link.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final unread = ref.watch(
      notificationsControllerProvider.select((s) => s.unreadCount),
    );

    return IconButton(
      tooltip: i18n.t('nav.notifications'),
      onPressed: () => _open(context, ref),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }

  Future<void> _open(BuildContext host, WidgetRef ref) async {
    unawaited(ref.read(notificationsControllerProvider.notifier).load());
    if (!host.mounted) return;
    await showModalBottomSheet<void>(
      context: host,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final i18n = ref.watch(i18nProvider);
            final items = ref.watch(notificationsControllerProvider).items;
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(title: Text(i18n.t('nav.notifications'))),
                  if (items.isEmpty)
                    ListTile(title: Text(i18n.t('notif.empty')))
                  else
                    for (final n in items)
                      ListTile(
                        leading: n.read
                            ? const SizedBox(width: 10)
                            : Icon(
                                Icons.circle,
                                size: 10,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        title: Text(n.title),
                        subtitle: Text(_subtitle(n)),
                        onTap: () {
                          final link = n.link;
                          unawaited(
                            ref
                                .read(notificationsControllerProvider.notifier)
                                .markRead(n.id),
                          );
                          Navigator.of(sheetContext).pop();
                          if (isKnownNotificationLink(link) && host.mounted) {
                            host.go(link!);
                          }
                        },
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _subtitle(AppNotification n) {
    final when = _when(n.createdAt);
    final body = n.body;
    if (body == null || body.isEmpty) return when;
    return '$body\n$when';
  }

  static String _when(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}
