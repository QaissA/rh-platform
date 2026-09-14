import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:alize_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = User(
  id: 1,
  email: 'ada@rh.local',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

const _unread = AppNotification(
  id: 9,
  kind: 'leave',
  title: 'Demande approuvée',
  body: 'Vos congés sont validés',
  link: '/conges',
  read: false,
  createdAt: '2026-09-09T10:00:00Z',
);

const _read = AppNotification(
  id: 10,
  kind: 'document',
  title: 'Document prêt',
  read: true,
  createdAt: '2026-09-08T08:30:00Z',
);

class ScriptedAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthSignedIn(Session(token: 'jwt', user: _user));

  void signOut() => state = const AuthSignedOut();
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({this.items = const [_unread, _read]});

  List<AppNotification> items;
  Result<List<AppNotification>>? listResult;
  Result<AppNotification>? readResult;
  final marked = <int>[];
  int listCalls = 0;

  @override
  Future<Result<List<AppNotification>>> list() async {
    listCalls++;
    return listResult ?? Result.ok(items);
  }

  @override
  Future<Result<AppNotification>> markRead(int id) async {
    marked.add(id);
    if (readResult != null) return readResult!;
    final updated = [
      for (final n in items)
        if (n.id == id)
          AppNotification(
            id: n.id,
            kind: n.kind,
            title: n.title,
            body: n.body,
            link: n.link,
            read: true,
            createdAt: n.createdAt,
          )
        else
          n,
    ];
    items = updated;
    return Result.ok(updated.firstWhere((n) => n.id == id));
  }
}

void main() {
  late FakeNotificationRepository repo;
  late ScriptedAuth auth;

  ProviderContainer createContainer() {
    auth = ScriptedAuth();
    repo = FakeNotificationRepository();
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => auth),
        notificationRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('unreadCount is the number of unread items after load', () async {
    final container = createContainer();

    await container.read(notificationsControllerProvider.notifier).load();

    expect(container.read(notificationsControllerProvider).items, hasLength(2));
    expect(container.read(notificationsControllerProvider).unreadCount, 1);
  });

  test('load failure keeps the last list or stays empty', () async {
    final container = createContainer();
    final notifier = container.read(notificationsControllerProvider.notifier);

    repo.listResult = const Result.err(Failure.network());
    await notifier.load();
    expect(container.read(notificationsControllerProvider).items, isEmpty);

    repo.listResult = null;
    await notifier.load();
    expect(container.read(notificationsControllerProvider).items, hasLength(2));

    repo.listResult = const Result.err(Failure.server(status: 500));
    await notifier.load();
    expect(container.read(notificationsControllerProvider).items, hasLength(2));
    expect(container.read(notificationsControllerProvider).unreadCount, 1);
  });

  test('markRead replaces the matching item and drops unreadCount', () async {
    final container = createContainer();
    final notifier = container.read(notificationsControllerProvider.notifier);
    await notifier.load();

    await notifier.markRead(9);

    expect(repo.marked, [9]);
    expect(container.read(notificationsControllerProvider).unreadCount, 0);
    expect(
      container.read(notificationsControllerProvider).items.first.read,
      isTrue,
    );
  });

  test('logout clears the list', () async {
    final container = createContainer();
    await container.read(notificationsControllerProvider.notifier).load();
    expect(container.read(notificationsControllerProvider).items, isNotEmpty);

    auth.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(notificationsControllerProvider).items, isEmpty);
    expect(container.read(notificationsControllerProvider).unreadCount, 0);
  });
}
