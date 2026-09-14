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
import 'package:alize_mobile/features/documents_rh/presentation/pages/documents_rh_edit_page.dart';
import 'package:alize_mobile/features/documents_rh/presentation/providers/documents_rh_providers.dart';
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
  FakeDocumentRepository({required this.doc});

  DocumentRequest doc;

  @override
  Future<Result<List<DocumentRequest>>> getRequests() async =>
      const Result.ok([]);

  @override
  Future<Result<List<DocumentRequest>>> getInbox({String? status}) async =>
      Result.ok([doc]);

  @override
  Future<Result<DocumentRequest>> create(NewDocumentRequest request) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> getRequest(int id) async => Result.ok(doc);

  @override
  Future<Result<DocumentRequest>> cancel(int id) async =>
      const Result.err(Failure.network());

  @override
  Future<Result<DocumentRequest>> update(
    int id, {
    Map<String, String>? fields,
    String? status,
    String? decisionComment,
  }) async {
    doc = DocumentRequest(
      id: doc.id,
      userId: doc.userId,
      docType: doc.docType,
      status: status != null ? DocumentStatus.fromWire(status) : doc.status,
      note: doc.note,
      fields: fields ?? doc.fields,
      issuedAt: doc.issuedAt,
      decisionComment: decisionComment ?? doc.decisionComment,
    );
    return Result.ok(doc);
  }

  @override
  Future<Result<DocumentRequest>> reject(int id, {String? comment}) async =>
      const Result.err(Failure.network());
}

class FakePeopleDirectory implements PeopleDirectory {
  FakePeopleDirectory(this.members);

  final Map<int, TeamMember> members;

  @override
  Future<Result<Map<int, TeamMember>>> load() async => Result.ok(members);

  @override
  TeamMember? get(int id) => members[id];

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

const _ada = TeamMember(
  id: 7,
  email: 'ada@rh.local',
  role: 'employee',
  firstName: 'Ada',
  lastName: 'Lovelace',
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

  testWidgets('edit page shows template field', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          documentRepositoryProvider.overrideWithValue(
            FakeDocumentRepository(doc: _pending),
          ),
          peopleDirectoryProvider.overrideWithValue(
            FakePeopleDirectory(const {7: _ada}),
          ),
          inboxBadgeProvider.overrideWith(TrackingInboxBadge.new),
        ],
        child: MaterialApp(
          theme: AlizeTheme.light(),
          home: const DocumentsRhEditPage(id: 21),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(i18n.t('docsRh.fields')), findsOneWidget);
    expect(find.text(i18n.t('docFields.employee_name')), findsOneWidget);
    expect(find.text(i18n.t('docType.work_certificate')), findsWidgets);
  });

  testWidgets('draft save reloads inbox as processing not pending',
      (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repo = FakeDocumentRepository(doc: _pending);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          i18nProvider.overrideWith((ref) => I18nController(i18n)),
          documentRepositoryProvider.overrideWithValue(repo),
          peopleDirectoryProvider.overrideWithValue(
            FakePeopleDirectory(const {7: _ada}),
          ),
          inboxBadgeProvider.overrideWith(TrackingInboxBadge.new),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            ref.watch(documentsRhControllerProvider);
            return MaterialApp(
              theme: AlizeTheme.light(),
              home: const DocumentsRhEditPage(id: 21),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final ctx = tester.element(find.byType(DocumentsRhEditPage));
    expect(
      ProviderScope.containerOf(ctx)
          .read(documentsRhControllerProvider)
          .requests
          .single
          .status,
      DocumentStatus.pending,
    );

    final saveButton =
        find.widgetWithText(OutlinedButton, i18n.t('common.save'));
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(repo.doc.status, DocumentStatus.processing);
    expect(
      ProviderScope.containerOf(ctx)
          .read(documentsRhControllerProvider)
          .requests
          .single
          .status,
      DocumentStatus.processing,
    );
  });
}
