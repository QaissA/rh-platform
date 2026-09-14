import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/error/result.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:alize_mobile/features/documents/domain/repositories/document_repository.dart';
import 'package:alize_mobile/features/documents/presentation/pages/documents_page.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class FakeDocumentRepository implements DocumentRepository {
  FakeDocumentRepository({this.mine = const []});

  final List<DocumentRequest> mine;

  @override
  Future<Result<List<DocumentRequest>>> getRequests() async => Result.ok(mine);

  @override
  Future<Result<List<DocumentRequest>>> getInbox({String? status}) async =>
      const Result.ok([]);

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

const _pending = DocumentRequest(
  id: 21,
  userId: 7,
  docType: 'work_certificate',
  status: DocumentStatus.pending,
  note: 'bank',
);

const _ready = DocumentRequest(
  id: 22,
  userId: 7,
  docType: 'salary_certificate',
  status: DocumentStatus.ready,
);

void main() {
  late I18n i18n;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    i18n = await I18n.load();
  });

  testWidgets(
    'fake repo splits pending vs ready on the status board',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            i18nProvider.overrideWith((ref) => I18nController(i18n)),
            documentRepositoryProvider.overrideWithValue(
              FakeDocumentRepository(mine: const [_pending, _ready]),
            ),
          ],
          child: MaterialApp(
            theme: AlizeTheme.light(),
            home: const DocumentsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(i18n.t('docs.withRh')), findsOneWidget);
      expect(find.text(i18n.t('docs.ready')), findsOneWidget);
      expect(find.text(i18n.t('docType.work_certificate')), findsOneWidget);
      expect(find.text(i18n.t('docType.salary_certificate')), findsOneWidget);
      expect(find.text(i18n.t('status.doc.pending')), findsOneWidget);
      expect(find.text('bank'), findsOneWidget);
    },
  );
}
