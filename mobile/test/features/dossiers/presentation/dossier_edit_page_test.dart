import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/update_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/user_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/repositories/dossier_repository.dart';
import 'package:alize_mobile/features/dossiers/presentation/pages/dossier_edit_page.dart';
import 'package:alize_mobile/features/dossiers/presentation/providers/dossier_providers.dart';
import 'package:alize_mobile/features/settings/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeDossierRepository implements DossierRepository {
  FakeDossierRepository(this.dossier);

  final UserDossier dossier;

  @override
  Future<Result<UserDossier>> getDossier(int id) async => Result.ok(dossier);

  @override
  Future<Result<UserDossier>> updateDossier(
    int id,
    UpdateDossier payload,
  ) async =>
      Result.ok(dossier);

  @override
  Future<Result<UserDossier>> acceptJobTitle(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<UserDossier>> rejectJobTitle(int id, {String? comment}) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<UserDossier>> unlockSignature(int id) async =>
      const Result.err(Failure.network());
}

const _dossier = UserDossier(
  profile: UserProfile(
    id: 7,
    email: 'ada@rh.local',
    role: 'employee',
    firstName: 'Ada',
    lastName: 'Lovelace',
    jobTitle: 'Engineer',
    addressLine: '12 rue X',
    postalCode: '75001',
    city: 'Paris',
    country: 'FR',
  ),
  salaryCents: 320000,
  contractType: 'cdi',
  hiredOn: '2024-03-01',
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets('detail has salary field', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          dossierRepositoryProvider.overrideWithValue(
            FakeDossierRepository(_dossier),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const DossierEditPage(id: 7),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('dossiers.salary')), findsOneWidget);
    expect(find.byKey(DossierEditPage.salaryFieldKey), findsOneWidget);
  });
}
