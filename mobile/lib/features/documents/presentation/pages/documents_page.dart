import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:alize_mobile/features/documents/domain/entities/new_document_request.dart';
import 'package:alize_mobile/features/documents/presentation/document_labels.dart';
import 'package:alize_mobile/features/documents/presentation/providers/document_providers.dart';
import 'package:alize_mobile/features/documents/presentation/widgets/document_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _DocumentsView(),
    );
  }
}

class _DocumentsView extends ConsumerStatefulWidget {
  const _DocumentsView();

  @override
  ConsumerState<_DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends ConsumerState<_DocumentsView> {
  String _docType = documentTypeCodes.first;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final controller = ref.read(documentsControllerProvider.notifier);
    if (ref.read(documentsControllerProvider).submitting) return;
    final note = _note.text.trim();
    final result = await controller.submit(
      NewDocumentRequest(
        docType: _docType,
        note: note.isEmpty ? null : note,
      ),
    );
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isOk ? i18n.t('docs.created') : i18n.t('docs.createFail'),
        ),
      ),
    );
    if (result.isOk) _note.clear();
  }

  Future<void> _cancel(DocumentRequest request) async {
    final result =
        await ref.read(documentsControllerProvider.notifier).cancel(request.id);
    if (!mounted) return;
    final i18n = ref.read(i18nProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isOk ? i18n.t('docs.cancelled') : i18n.t('docs.cancelFail'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(documentsControllerProvider);
    final colors = documentPaletteOf(context);
    final waiting =
        state.requests.where((r) => r.status.isOpen).toList(growable: false);
    final ready = state.requests
        .where((r) => r.status == DocumentStatus.ready)
        .toList(growable: false);
    final closed = state.requests
        .where(
          (r) =>
              r.status == DocumentStatus.rejected ||
              r.status == DocumentStatus.cancelled,
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(documentsControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i18n.t('docs.title'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.t('docs.help'),
                        style: TextStyle(fontSize: 13, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(documentsControllerProvider.notifier)
                      .toggleForm(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(i18n.t('common.newRequest')),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (state.formOpen) ...[
              const SizedBox(height: 14),
              _NewRequestForm(
                colors: colors,
                i18n: i18n,
                docType: _docType,
                note: _note,
                submitting: state.submitting,
                onType: (value) => setState(() => _docType = value),
                onCancel: () => ref
                    .read(documentsControllerProvider.notifier)
                    .closeForm(),
                onSubmit: _submit,
              ),
            ],
            const SizedBox(height: 14),
            if (state.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
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
                      i18n.t('common.loading'),
                      style: TextStyle(color: colors.ink2),
                    ),
                  ],
                ),
              )
            else if (state.requests.isEmpty)
              _EmptyDocuments(
                colors: colors,
                i18n: i18n,
                onNew: () =>
                    ref.read(documentsControllerProvider.notifier).toggleForm(),
              )
            else ...[
              _BoardCard(
                colors: colors,
                title: i18n.t('docs.withRh'),
                empty: i18n.t('docs.nothingOpen'),
                child: waiting.isEmpty
                    ? null
                    : Column(
                        children: [
                          for (final doc in waiting)
                            _WaitingRow(
                              doc: doc,
                              colors: colors,
                              i18n: i18n,
                              busy: state.busyId == doc.id,
                              onCancel: () => _cancel(doc),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              _BoardCard(
                colors: colors,
                title: i18n.t('docs.ready'),
                empty: i18n.t('docs.noReady'),
                child: ready.isEmpty
                    ? null
                    : Column(
                        children: [
                          for (final doc in ready)
                            _ReadyRow(
                              doc: doc,
                              colors: colors,
                              i18n: i18n,
                              onOpen: () => context.go('/documents/${doc.id}'),
                            ),
                        ],
                      ),
              ),
              if (closed.isNotEmpty) ...[
                const SizedBox(height: 12),
                _BoardCard(
                  colors: colors,
                  title: i18n.t('docs.closed'),
                  empty: '',
                  child: Column(
                    children: [
                      for (final doc in closed)
                        _ClosedRow(doc: doc, colors: colors, i18n: i18n),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _NewRequestForm extends StatelessWidget {
  const _NewRequestForm({
    required this.colors,
    required this.i18n,
    required this.docType,
    required this.note,
    required this.submitting,
    required this.onType,
    required this.onCancel,
    required this.onSubmit,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final String docType;
  final TextEditingController note;
  final bool submitting;
  final ValueChanged<String> onType;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.brand600),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              i18n.t('docs.newTitle'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              i18n.t('docs.type'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            InputDecorator(
              decoration: _inputDecoration(colors),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: docType,
                  isExpanded: true,
                  items: [
                    for (final code in documentTypeCodes)
                      DropdownMenuItem(
                        value: code,
                        child: Text(i18n.t('docType.$code')),
                      ),
                  ],
                  onChanged: submitting
                      ? null
                      : (value) {
                          if (value != null) onType(value);
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              i18n.t('docs.details'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: _inputDecoration(colors).copyWith(
                hintText: i18n.t('docs.detailsPlaceholder'),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: Text(i18n.t('common.cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: submitting ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                  ),
                  child: submitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(i18n.t('common.sending')),
                          ],
                        )
                      : Text(i18n.t('common.submitRequest')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.colors,
    required this.title,
    required this.empty,
    required this.child,
  });

  final AlizePalette colors;
  final String title;
  final String empty;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 10),
            if (child == null)
              Text(empty, style: TextStyle(fontSize: 13, color: colors.ink2))
            else
              child!,
          ],
        ),
      ),
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow({
    required this.doc,
    required this.colors,
    required this.i18n,
    required this.busy,
    required this.onCancel,
  });

  final DocumentRequest doc;
  final AlizePalette colors;
  final I18nController i18n;
  final bool busy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.t('docType.${doc.docType}'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                if (doc.note != null && doc.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      doc.note!,
                      style: TextStyle(fontSize: 12.5, color: colors.ink3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DocumentStatusChip(
                status: doc.status,
                label: i18n.t('status.doc.${doc.status.wire}'),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: busy ? null : onCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.bad,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(i18n.t('common.cancel')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({
    required this.doc,
    required this.colors,
    required this.i18n,
    required this.onOpen,
  });

  final DocumentRequest doc;
  final AlizePalette colors;
  final I18nController i18n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              i18n.t('docType.${doc.docType}'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ),
          FilledButton(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: colors.brand,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(i18n.t('common.open')),
          ),
        ],
      ),
    );
  }
}

class _ClosedRow extends StatelessWidget {
  const _ClosedRow({
    required this.doc,
    required this.colors,
    required this.i18n,
  });

  final DocumentRequest doc;
  final AlizePalette colors;
  final I18nController i18n;

  @override
  Widget build(BuildContext context) {
    final detail = (doc.decisionComment != null &&
            doc.decisionComment!.isNotEmpty)
        ? doc.decisionComment!
        : doc.note;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i18n.t('docType.${doc.docType}'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                if (detail != null && detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      detail,
                      style: TextStyle(fontSize: 12.5, color: colors.ink3),
                    ),
                  ),
              ],
            ),
          ),
          DocumentStatusChip(
            status: doc.status,
            label: i18n.t('status.doc.${doc.status.wire}'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments({
    required this.colors,
    required this.i18n,
    required this.onNew,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 36, color: colors.ink3),
            const SizedBox(height: 12),
            Text(
              i18n.t('docs.empty'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.ink2, height: 1.4),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onNew,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
              ),
              child: Text(i18n.t('common.newRequest')),
            ),
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
