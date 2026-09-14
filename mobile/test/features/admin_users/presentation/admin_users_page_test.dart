import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/created_user.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/new_user.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/update_user.dart';
import 'package:alize_mobile/features/admin_users/domain/repositories/user_admin_repository.dart';
import 'package:alize_mobile/features/admin_users/presentation/pages/admin_user_form_page.dart';
import 'package:alize_mobile/features/admin_users/presentation/pages/admin_users_page.dart';
import 'package:alize_mobile/features/admin_users/presentation/providers/user_admin_providers.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeUserAdminRepository implements UserAdminRepository {
  FakeUserAdminRepository({this.users = const [], this.created});

  final List<User> users;
  final CreatedUser? created;

  @override
  Future<Result<List<User>>> list() async {
    await Future<void>.delayed(Duration.zero);
    return Result.ok(users);
  }

  @override
  Future<Result<CreatedUser>> create(NewUser payload) async {
    final user = created;
    if (user == null) return const Result.err(Failure.network());
    return Result.ok(user);
  }

  @override
  Future<Result<User>> update(int id, UpdateUser payload) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<void>> remove(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<CreatedUser>> resetPassword(int id) async =>
      const Result.err(Failure.network());
}

const _ada = User(
  id: 7,
  email: 'ada@rh.local',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

const _created = CreatedUser(
  user: _ada,
  temporaryPassword: 'Temp-Once-9',
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets('list renders a user email', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          userAdminRepositoryProvider.overrideWithValue(
            FakeUserAdminRepository(users: const [_ada]),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const AdminUsersPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('users.title')), findsOneWidget);
    expect(find.text('ada@rh.local'), findsOneWidget);
  });

  testWidgets('create shows temporary password from fake repo', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          userAdminRepositoryProvider.overrideWithValue(
            FakeUserAdminRepository(created: _created),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const AdminUserFormPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(
      find.byKey(const Key('admin-user-email')),
      'ada@rh.local',
    );
    await tester.pump();
    await tester.tap(find.text(i18n.t('users.create')));
    await tester.pump();
    await tester.pump();

    expect(find.text(i18n.t('users.createdTitle')), findsOneWidget);
    expect(find.text('Temp-Once-9'), findsOneWidget);
  });
}
