import 'dart:async';

import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/documents/domain/document_templates.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/presentation/document_labels.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/documents/presentation/widgets/document_pdf_actions.dart';
import 'package:alize_mobile/features/documents/presentation/widgets/document_preview.dart';
import 'package:alize_mobile/features/documents/presentation/widgets/document_status_chip.dart';
import 'package:alize_mobile/features/documents_rh/presentation/providers/documents_rh_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DocumentsRhEditPage extends ConsumerStatefulWidget {
  const DocumentsRhEditPage({super.key, required this.id});

  final int id;

  @override
  ConsumerState<DocumentsRhEditPage> createState() =>
      _DocumentsRhEditPageState();
}

class _DocumentsRhEditPageState extends ConsumerState<DocumentsRhEditPage> {
  var _loading = true;
  var _saving = false;
  var _rejecting = false;
  DocumentRequest? _doc;
  var _fields = <String, String>{};
  var _template = const <TemplateField>[];
  final _controllers = <String, TextEditingController>{};
  final _rejectComment = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _rejectComment.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result =
        await ref.read(documentRepositoryProvider).getRequest(widget.id);
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    final doc = result.data;
    if (!result.isOk || doc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('docsRh.notFound'))),
      );
      context.go('/documents-rh');
      return;
    }
    await _hydrate(doc);
  }

  Future<void> _hydrate(DocumentRequest doc) async {
    final i18n = ref.read(i18nProvider);
    final people = ref.read(peopleDirectoryProvider);
    await people.load();
    if (!mounted) return;
    final name = people.nameOf(doc.userId);
    final template =
        templateFields[doc.docType] ?? templateFields['other']!;
    final fields = {
      ...defaultDocFields(
        docType: doc.docType,
        employeeName: name,
        note: doc.note,
        t: i18n.t,
      ),
      ...?doc.fields,
    };
    for (final field in template) {
      final existing = _controllers[field.key];
      if (existing == null) {
        _controllers[field.key] = TextEditingController(
          text: fields[field.key] ?? '',
        );
      } else if (existing.text != (fields[field.key] ?? '')) {
        existing.text = fields[field.key] ?? '';
      }
    }
    setState(() {
      _doc = DocumentRequest(
        id: doc.id,
        userId: doc.userId,
        docType: doc.docType,
        status: doc.status,
        note: doc.note,
        fields: fields,
        issuedAt: doc.issuedAt,
        decisionComment: doc.decisionComment,
      );
      _fields = fields;
      _template = template;
      _loading = false;
    });
  }

  DocumentRequest get _previewDoc {
    final doc = _doc!;
    return DocumentRequest(
      id: doc.id,
      userId: doc.userId,
      docType: doc.docType,
      status: doc.status,
      note: doc.note,
      fields: Map<String, String>.from(_fields),
      issuedAt: doc.issuedAt,
      decisionComment: doc.decisionComment,
    );
  }

  Map<String, String> _readFields() {
    return {
      for (final field in _template)
        field.key: _controllers[field.key]?.text ?? _fields[field.key] ?? '',
    };
  }

  Future<void> _save({String? status}) async {
    final doc = _doc;
    if (doc == null || _saving) return;
    setState(() => _saving = true);
    final fields = _readFields();
    final nextStatus = status ??
        (doc.status == DocumentStatus.pending ? 'processing' : null);
    final result = await ref.read(documentRepositoryProvider).update(
          doc.id,
          fields: fields,
          status: nextStatus,
        );
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    if (!result.isOk || result.data == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('docsRh.saveFail'))),
      );
      return;
    }
    await _hydrate(result.data!);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(status == 'ready' ? 'docsRh.savedReady' : 'docsRh.savedDraft'),
        ),
      ),
    );
    await ref
        .read(documentsRhControllerProvider.notifier)
        .reload(showSpinner: false);
    if (status == 'ready') {
      await ref.read(inboxBadgeProvider.notifier).refresh();
    }
  }

  Future<void> _confirmReject() async {
    final doc = _doc;
    if (doc == null || _saving) return;
    setState(() => _saving = true);
    final comment = _rejectComment.text.trim();
    final result = await ref.read(documentRepositoryProvider).reject(
          doc.id,
          comment: comment.isEmpty ? null : comment,
        );
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    if (!result.isOk) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(i18n.t('docsRh.rejectFail'))),
      );
      return;
    }
    await ref.read(inboxBadgeProvider.notifier).refresh();
    await ref
        .read(documentsRhControllerProvider.notifier)
        .reload(showSpinner: false);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(i18n.t('docsRh.rejectedToast'))),
    );
    context.go('/documents-rh');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final colors = documentPaletteOf(context);
    final doc = _doc;
    final locked = doc != null &&
        (doc.status == DocumentStatus.rejected ||
            doc.status == DocumentStatus.cancelled);
    final editable = doc != null &&
        (doc.status == DocumentStatus.pending ||
            doc.status == DocumentStatus.processing ||
            doc.status == DocumentStatus.ready);

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
                      onPressed: () => context.go('/documents-rh'),
                      child: Text(i18n.t('docsRh.back')),
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
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DocumentStatusChip(
                        status: doc.status,
                        label: i18n.t('status.doc.${doc.status.wire}'),
                      ),
                      if (doc.note != null && doc.note!.isNotEmpty)
                        Text(
                          doc.note!,
                          style: TextStyle(fontSize: 13, color: colors.ink2),
                        ),
                    ],
                  ),
                  if (editable) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _saving ? null : () => _save(),
                          child: Text(i18n.t('common.save')),
                        ),
                        FilledButton(
                          onPressed: _saving ? null : () => _save(status: 'ready'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.brand,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(i18n.t('docsRh.makeReady')),
                        ),
                        DocumentPdfActions(doc: _previewDoc),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AlizeColors.radius),
                      border: Border.all(color: colors.line),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            i18n.t('docsRh.fields'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final field in _template) ...[
                            Text(
                              i18n.t('docFields.${field.key}'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _controllers[field.key],
                              enabled: !locked,
                              maxLines:
                                  field.type == TemplateFieldType.textarea
                                      ? 4
                                      : 1,
                              keyboardType:
                                  field.type == TemplateFieldType.date
                                      ? TextInputType.datetime
                                      : TextInputType.text,
                              decoration: _inputDecoration(colors),
                              onChanged: (value) {
                                setState(() {
                                  _fields = {..._fields, field.key: value};
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (locked)
                            Text(
                              doc.status == DocumentStatus.cancelled
                                  ? i18n.t('docsRh.cancelledByEmployee')
                                  : (doc.decisionComment != null &&
                                          doc.decisionComment!.isNotEmpty)
                                      ? i18n.t(
                                          'docsRh.rejectedWith',
                                          {'comment': doc.decisionComment!},
                                        )
                                      : i18n.t('docsRh.rejected'),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.ink2,
                              ),
                            )
                          else if (_rejecting) ...[
                            Text(
                              i18n.t('common.rejectReason'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _rejectComment,
                              decoration: _inputDecoration(colors),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _rejecting = false),
                                  child: Text(i18n.t('common.cancel')),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _saving ? null : _confirmReject,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colors.bad,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(i18n.t('docsRh.confirmReject')),
                                ),
                              ],
                            ),
                          ] else if (doc.status == DocumentStatus.pending ||
                              doc.status == DocumentStatus.processing)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _rejecting = true),
                                style: TextButton.styleFrom(
                                  foregroundColor: colors.bad,
                                ),
                                child: Text(i18n.t('docsRh.rejectLink')),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DocumentPreview(doc: _previewDoc),
                ],
              ),
      ),
    );
  }
}

InputDecoration _inputDecoration(AlizePalette colors) {
  return InputDecoration(
    filled: true,
    fillColor: colors.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.brand),
    ),
  );
}
