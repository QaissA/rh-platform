import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:alize_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/documents_rh/presentation/pages/documents_rh_page.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/people_directory.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart' as format;
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({this.inbox = const []});

  final List<DocumentRequest> inbox;

  @override
  Future<Result<List<DocumentRequest>>> getRequests() async =>
      const Result.ok([]);

  @override
  Future<Result<List<DocumentRequest>>> getInbox({String? status}) async =>
      Result.ok(inbox);

  @override
  Future<Result<DocumentRequest>> create(NewDocumentRequest request) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> getRequest(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> cancel(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> update(
    int id, {
    Map<String, String>? fields,
    String? status,
    String? decisionComment,
  }) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> reject(int id, {String? comment}) async =>
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
    );
  }
}

class TrackingInboxBadge extends InboxBadgeNotifier {
  @override
  InboxBadgeState build() => const InboxBadgeState();

  @override
  Future<void> refresh() async {}
}

const _alan = TeamMember(
  id: 7,
  email: 'alan@rh.local',
  role: 'employee',
  firstName: 'Alan',
  lastName: 'Turing',
  jobTitle: 'Dev',
);

const _pending = DocumentRequest(
  id: 21,
  userId: 7,
  docType: 'work_certificate',
  status: DocumentStatus.pending,
  note: 'bank',
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets('inbox lists a pending request', (tester) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          documentRepositoryProvider.overrideWithValue(
            FakeDocumentRepository(inbox: const [_pending]),
          ),
          peopleDirectoryProvider.overrideWithValue(
            FakePeopleDirectory(const {7: _alan}),
          ),
          inboxBadgeProvider.overrideWith(TrackingInboxBadge.new),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const DocumentsRhPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('docsRh.title')), findsOneWidget);
    expect(find.text('Collaborateur #7'), findsNothing);
    expect(find.text('Alan Turing'), findsOneWidget);
    expect(find.text(i18n.t('docType.work_certificate')), findsOneWidget);
    expect(find.text(i18n.t('docsRh.draft')), findsOneWidget);
    expect(find.text('bank'), findsOneWidget);
  });
}
