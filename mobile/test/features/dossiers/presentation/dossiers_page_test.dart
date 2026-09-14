import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/update_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/user_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/repositories/dossier_repository.dart';
import 'package:alize_mobile/features/dossiers/presentation/pages/dossiers_page.dart';
import 'package:alize_mobile/features/dossiers/presentation/providers/dossier_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/people_directory.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart' as format;
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeDossierRepository implements DossierRepository {
  @override
  Future<Result<UserDossier>> getDossier(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<UserDossier>> updateDossier(
    int id,
    UpdateDossier payload,
  ) async =>
      const Result.err(Failure.network());

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

class FakePeopleDirectory implements PeopleDirectory {
  FakePeopleDirectory(this.members);

  final Map<int, TeamMember> members;
  Map<int, TeamMember> _loaded = {};

  @override
  Future<Result<Map<int, TeamMember>>> load() async {
    await Future<void>.delayed(Duration.zero);
    _loaded = Map.of(members);
    return Result.ok(_loaded);
  }

  @override
  TeamMember? get(int id) => _loaded[id];

  @override
  String nameOf(int id) {
    final member = get(id);
    return member == null ? 'Collaborateur #$id' : format.fullName(member);
  }

  @override
  String? jobTitleOf(int id) => format.jobTitleOf(get(id));

  @override
  String initialsOf(int id) {
    final member = get(id);
    return member == null ? '?' : format.initialsOf(member);
  }

  @override
  TeamMember toMember(User user) {
    return TeamMember(
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      jobTitle: user.jobTitle,
      pendingJobTitle: user.pendingJobTitle,
    );
  }
}

const _ada = TeamMember(
  id: 7,
  email: 'ada@rh.local',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
  jobTitle: 'Engineer',
);

const _alan = TeamMember(
  id: 9,
  email: 'alan@rh.local',
  role: 'employee',
  firstName: 'Alan',
  lastName: 'Turing',
  jobTitle: 'Dev',
  pendingJobTitle: 'Lead',
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets('list shows employee names', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          dossierRepositoryProvider.overrideWithValue(FakeDossierRepository()),
          peopleDirectoryProvider.overrideWithValue(
            FakePeopleDirectory(const {7: _ada, 9: _alan}),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const DossiersPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('dossiers.title')), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Alan Turing'), findsWidgets);
  });
}
