import 'dart:async';

import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/presentation/document_labels.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/documents/presentation/widgets/document_pdf_actions.dart';
import 'package:alize_mobile/features/documents/presentation/widgets/document_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DocumentDetailPage extends ConsumerStatefulWidget {
  const DocumentDetailPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends ConsumerState<DocumentDetailPage> {
  var _loading = true;
  DocumentRequest? _doc;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result =
        await ref.read(documentRepositoryProvider).getRequest(widget.id);
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    final doc = result.data;
    if (!result.isOk || doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('docs.notFound'))),
      );
      context.go('/documents');
      return;
    }
    if (doc.status != DocumentStatus.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('docs.notReady'))),
      );
      context.go('/documents');
      return;
    }
    setState(() {
      _doc = doc;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final colors = documentPaletteOf(context);
    final doc = _doc;

    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colors.paper,
        body: _loading || doc == null
            ? Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      i18n.t('docs.loadingDoc'),
                      style: TextStyle(color: colors.ink2),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.go('/documents'),
                      child: Text(i18n.t('docs.backMine')),
                    ),
                  ),
                  Text(
                    i18n.t('docType.${doc.docType}'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    i18n.t('docs.viewHelp'),
                    style: TextStyle(fontSize: 13, color: colors.ink2),
                  ),
                  const SizedBox(height: 12),
                  DocumentPdfActions(doc: doc),
                  const SizedBox(height: 16),
                  DocumentPreview(doc: doc),
                ],
              ),
      ),
    );
  }
}
