import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/session.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/my_team.dart';
import 'package:alize_mobile/features/team/domain/entities/new_presence.dart';
import 'package:alize_mobile/features/team/domain/entities/schedule_entry.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/repositories/schedule_repository.dart';
import 'package:alize_mobile/features/team/domain/repositories/team_repository.dart';
import 'package:alize_mobile/features/team/presentation/pages/team_page.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeTeamRepository implements TeamRepository {
  FakeTeamRepository({required this.roster});

  final MyTeam roster;

  @override
  Future<Result<MyTeam>> getMine() async => Result.ok(roster);
}

class FakeScheduleRepository implements ScheduleRepository {
  @override
  Future<Result<ScheduleSnapshot>> getSchedule({
    required String start,
    required String end,
  }) async {
    return const Result.ok(
      ScheduleSnapshot(start: '2026-09-01', end: '2026-09-30', entries: []),
    );
  }

  @override
  Future<Result<List<ScheduleEntry>>> declarePresence(
    NewPresence presence,
  ) async {
    return const Result.err(Failure.network());
  }
}

class _SignedInAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthSignedIn(
        Session(
          token: 'jwt',
          user: User(
            id: 1,
            email: 'ada@rh.local',
            role: 'employee',
            firstName: 'Ada',
            lastName: 'Lovelace',
          ),
        ),
      );
}

const _alan = TeamMember(
  id: 8,
  email: 'alan@rh.local',
  role: 'employee',
  firstName: 'Alan',
  lastName: 'Turing',
  jobTitle: 'Dev',
);

const _grace = TeamMember(
  id: 9,
  email: 'grace@rh.local',
  role: 'manager',
  firstName: 'Grace',
  lastName: 'Hopper',
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets('fake team members render', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          authProvider.overrideWith(_SignedInAuth.new),
          teamRepositoryProvider.overrideWithValue(
            FakeTeamRepository(
              roster: const MyTeam(
                team: TeamRef(id: 3, name: 'Plateforme'),
                members: [_alan, _grace],
              ),
            ),
          ),
          scheduleRepositoryProvider.overrideWithValue(
            FakeScheduleRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const TeamPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Alan Turing'), findsOneWidget);
    expect(find.text('Grace Hopper'), findsOneWidget);
  });
}
