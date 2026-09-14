import 'dart:async';

import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/features/documents/data/document_pdf.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/presentation/document_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

class DocumentPdfActions extends ConsumerWidget {
  const DocumentPdfActions({super.key, required this.doc});

  final DocumentRequest doc;

  Future<void> _print(BuildContext context, WidgetRef ref) async {
    final i18n = ref.read(i18nProvider);
    try {
      final bytes = await buildPdf(doc, i18n.t);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('docs.downloadFail'))),
      );
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final i18n = ref.read(i18nProvider);
    try {
      final bytes = await buildPdf(doc, i18n.t);
      await Printing.sharePdf(
        bytes: bytes,
        filename: documentFileName(doc, i18n.t),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('docs.downloadFail'))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final colors = documentPaletteOf(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () => unawaited(_print(context, ref)),
          child: Text(i18n.t('common.print')),
        ),
        FilledButton(
          onPressed: () => unawaited(_share(context, ref)),
          style: FilledButton.styleFrom(
            backgroundColor: colors.brand,
            foregroundColor: Colors.white,
          ),
          child: Text(i18n.t('common.download')),
        ),
      ],
    );
  }
}
