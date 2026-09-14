import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/storage/session_store.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:alize_mobile/features/auth/presentation/pages/change_password_page.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/settings/domain/entities/update_profile.dart';
import 'package:alize_mobile/features/settings/domain/entities/user_profile.dart';
import 'package:alize_mobile/features/settings/domain/repositories/profile_repository.dart';
import 'package:alize_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:alize_mobile/features/settings/presentation/providers/settings_providers.dart';
import 'package:alize_mobile/features/settings/presentation/widgets/signature_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// 1×1 PNG so Image.memory can decode the locked preview.
const _pngDataUrl =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

const _unlocked = UserProfile(
  id: 1,
  email: 'a@b.com',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
  jobTitle: 'Engineer',
  addressLine: '12 rue X',
  postalCode: '75001',
  city: 'Paris',
  country: 'FR',
  signatureLocked: false,
);

const _locked = UserProfile(
  id: 1,
  email: 'a@b.com',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
  signaturePng: _pngDataUrl,
  signatureLocked: true,
);

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.profile);

  UserProfile profile;

  @override
  Future<Result<UserProfile>> getMine() async => Result.ok(profile);

  @override
  Future<Result<UserProfile>> updateMine(UpdateProfile payload) async =>
      Result.ok(profile);
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<Result<Session>> login({
    required String email,
    required String password,
  }) async {
    return const Result.err(Failure.unauthorized());
  }

  @override
  Future<Result<User>> me() async => const Result.err(Failure.unauthorized());

  @override
  Future<Result<User>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Result.err(Failure.unauthorized());
  }
}

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required UserProfile profile,
  }) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(profile),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('locked profile hides the pad and shows the stored image',
      (tester) async {
    await pumpPage(tester, profile: _locked);

    expect(find.byType(SignaturePad), findsNothing);
    expect(find.byKey(SettingsPage.signatureImageKey), findsOneWidget);
    expect(find.text(i18n.t('settings.lockedHelp')), findsOneWidget);
  });

  testWidgets('unlocked profile shows the signature pad', (tester) async {
    await pumpPage(tester, profile: _unlocked);

    expect(find.byType(SignaturePad), findsOneWidget);
    expect(find.byKey(SettingsPage.signatureImageKey), findsNothing);
  });

  testWidgets('password shorter than change-password min length disables submit',
      (tester) async {
    await pumpPage(tester, profile: _unlocked);

    await tester.enterText(
      find.byKey(SettingsPage.currentPasswordFieldKey),
      'old-pass',
    );
    await tester.enterText(
      find.byKey(SettingsPage.newPasswordFieldKey),
      'short',
    );
    await tester.enterText(
      find.byKey(SettingsPage.confirmPasswordFieldKey),
      'short',
    );
    await tester.pump();

    expect('short'.length, lessThan(ChangePasswordPage.minLength));
    final submit = find.widgetWithText(
      FilledButton,
      i18n.t('settings.changePassword'),
    );
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(find.text(i18n.t('settings.tooShort')), findsOneWidget);
  });
}
