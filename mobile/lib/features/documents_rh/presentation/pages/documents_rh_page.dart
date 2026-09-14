import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/presentation/document_labels.dart';
import 'package:alize_mobile/features/documents/presentation/widgets/document_status_chip.dart';
import 'package:alize_mobile/features/documents_rh/presentation/providers/documents_rh_providers.dart';
import 'package:alize_mobile/features/team/presentation/providers/team_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DocumentsRhPage extends ConsumerWidget {
  const DocumentsRhPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _DocumentsRhView(),
    );
  }
}

class _DocumentsRhView extends ConsumerStatefulWidget {
  const _DocumentsRhView();

  @override
  ConsumerState<_DocumentsRhView> createState() => _DocumentsRhViewState();
}

class _DocumentsRhViewState extends ConsumerState<_DocumentsRhView> {
  final _rejectComment = TextEditingController();

  @override
  void dispose() {
    _rejectComment.dispose();
    super.dispose();
  }

  Future<void> _confirmReject(DocumentRequest request) async {
    final comment = _rejectComment.text.trim();
    final result = await ref
        .read(documentsRhControllerProvider.notifier)
        .reject(request.id, comment: comment.isEmpty ? null : comment);
    if (!mounted) return;
    _rejectComment.clear();
    final i18n = ref.read(i18nProvider);
    final name = ref.read(peopleDirectoryProvider).nameOf(request.userId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isOk
              ? i18n.t('docsRh.rejectedFor', {'name': name})
              : i18n.t('docsRh.rejectFail'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(documentsRhControllerProvider);
    final colors = documentPaletteOf(context);
    final openOnly = state.filter == DocumentsRhFilter.open;

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(documentsRhControllerProvider.notifier).reload(),
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
                        i18n.t('docsRh.title'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.t('docsRh.help'),
                        style: TextStyle(fontSize: 13, color: colors.ink2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    _FilterButton(
                      colors: colors,
                      label: i18n.t('docsRh.open'),
                      selected: openOnly,
                      onTap: () => ref
                          .read(documentsRhControllerProvider.notifier)
                          .setFilter(DocumentsRhFilter.open),
                    ),
                    const SizedBox(height: 6),
                    _FilterButton(
                      colors: colors,
                      label: i18n.t('docsRh.all'),
                      selected: !openOnly,
                      onTap: () => ref
                          .read(documentsRhControllerProvider.notifier)
                          .setFilter(DocumentsRhFilter.all),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _KpiTile(
                    colors: colors,
                    figure: '${state.openCount}',
                    unit: i18n.t('docsRh.openCount'),
                    sub: i18n.t('docsRh.openSub'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KpiTile(
                    colors: colors,
                    figure: '${state.requests.length}',
                    sub: i18n.t(openOnly ? 'docsRh.open' : 'docsRh.all'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    Flexible(
                      child: Text(
                        i18n.t('docsRh.loading'),
                        style: TextStyle(color: colors.ink2),
                      ),
                    ),
                  ],
                ),
              )
            else if (openOnly)
              _BoardCard(
                colors: colors,
                title: i18n.t('docsRh.open'),
                empty: i18n.t('docsRh.emptyOpen'),
                child: state.requests.isEmpty
                    ? null
                    : Column(
                        children: [
                          for (final doc in state.requests)
                            _InboxRow(
                              doc: doc,
                              colors: colors,
                              i18n: i18n,
                              busy: state.busyId == doc.id,
                              rejecting: state.rejectingId == doc.id,
                              rejectComment: _rejectComment,
                              onDraft: () =>
                                  context.go('/documents-rh/${doc.id}'),
                              onAskReject: () {
                                _rejectComment.clear();
                                ref
                                    .read(
                                      documentsRhControllerProvider.notifier,
                                    )
                                    .askReject(doc.id);
                              },
                              onCancelReject: () {
                                _rejectComment.clear();
                                ref
                                    .read(
                                      documentsRhControllerProvider.notifier,
                                    )
                                    .cancelReject();
                              },
                              onConfirmReject: () => _confirmReject(doc),
                            ),
                        ],
                      ),
              )
            else ...[
              _BoardCard(
                colors: colors,
                title: i18n.t('docsRh.open'),
                empty: i18n.t('docsRh.emptyOpen'),
                child: state.openRows.isEmpty
                    ? null
                    : Column(
                        children: [
                          for (final doc in state.openRows)
                            _InboxRow(
                              doc: doc,
                              colors: colors,
                              i18n: i18n,
                              busy: state.busyId == doc.id,
                              rejecting: state.rejectingId == doc.id,
                              rejectComment: _rejectComment,
                              onDraft: () =>
                                  context.go('/documents-rh/${doc.id}'),
                              onAskReject: () {
                                _rejectComment.clear();
                                ref
                                    .read(
                                      documentsRhControllerProvider.notifier,
                                    )
                                    .askReject(doc.id);
                              },
                              onCancelReject: () {
                                _rejectComment.clear();
                                ref
                                    .read(
                                      documentsRhControllerProvider.notifier,
                                    )
                                    .cancelReject();
                              },
                              onConfirmReject: () => _confirmReject(doc),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              _BoardCard(
                colors: colors,
                title: i18n.t('docsRh.ready'),
                empty: i18n.t('docsRh.emptyReady'),
                child: state.readyRows.isEmpty
                    ? null
                    : Column(
                        children: [
                          for (final doc in state.readyRows)
                            _ReadyRow(
                              doc: doc,
                              colors: colors,
                              i18n: i18n,
                              onOpen: () =>
                                  context.go('/documents-rh/${doc.id}'),
                            ),
                        ],
                      ),
              ),
              if (state.closedRows.isNotEmpty) ...[
                const SizedBox(height: 12),
                _BoardCard(
                  colors: colors,
                  title: i18n.t('docsRh.closed'),
                  empty: '',
                  child: Column(
                    children: [
                      for (final doc in state.closedRows)
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AlizePalette colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: selected
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(label),
            ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.colors,
    required this.figure,
    required this.sub,
    this.unit,
  });

  final AlizePalette colors;
  final String figure;
  final String sub;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: figure,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.ink,
                ),
                children: [
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.ink2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: TextStyle(fontSize: 11, color: colors.ink2),
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

class _InboxRow extends ConsumerWidget {
  const _InboxRow({
    required this.doc,
    required this.colors,
    required this.i18n,
    required this.busy,
    required this.rejecting,
    required this.rejectComment,
    required this.onDraft,
    required this.onAskReject,
    required this.onCancelReject,
    required this.onConfirmReject,
  });

  final DocumentRequest doc;
  final AlizePalette colors;
  final I18nController i18n;
  final bool busy;
  final bool rejecting;
  final TextEditingController rejectComment;
  final VoidCallback onDraft;
  final VoidCallback onAskReject;
  final VoidCallback onCancelReject;
  final VoidCallback onConfirmReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleDirectoryProvider);
    final name = people.nameOf(doc.userId);
    final jobTitle = people.jobTitleOf(doc.userId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                    if (jobTitle != null)
                      Text(
                        jobTitle,
                        style: TextStyle(fontSize: 12, color: colors.ink2),
                      ),
                    Text(
                      i18n.t('docType.${doc.docType}'),
                      style: TextStyle(fontSize: 13, color: colors.ink2),
                    ),
                    if (doc.note != null && doc.note!.isNotEmpty)
                      Text(
                        doc.note!,
                        style: TextStyle(fontSize: 12.5, color: colors.ink3),
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
          const SizedBox(height: 8),
          if (rejecting)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: rejectComment,
                  decoration: InputDecoration(
                    hintText: i18n.t('common.rejectReason'),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton(
                      onPressed: busy ? null : onConfirmReject,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.bad,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(i18n.t('common.confirm')),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: busy ? null : onCancelReject,
                      child: Text(i18n.t('common.cancel')),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                OutlinedButton(
                  onPressed: onDraft,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(i18n.t('docsRh.draft')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: busy ? null : onAskReject,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.bad,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(i18n.t('common.reject')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReadyRow extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleDirectoryProvider);
    final name = people.nameOf(doc.userId);
    final jobTitle = people.jobTitleOf(doc.userId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                if (jobTitle != null)
                  Text(
                    jobTitle,
                    style: TextStyle(fontSize: 12, color: colors.ink2),
                  ),
                Text(
                  i18n.t('docType.${doc.docType}'),
                  style: TextStyle(fontSize: 13, color: colors.ink2),
                ),
              ],
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

class _ClosedRow extends ConsumerWidget {
  const _ClosedRow({
    required this.doc,
    required this.colors,
    required this.i18n,
  });

  final DocumentRequest doc;
  final AlizePalette colors;
  final I18nController i18n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(peopleDirectoryProvider);
    final name = people.nameOf(doc.userId);
    final jobTitle = people.jobTitleOf(doc.userId);
    final reason = (doc.decisionComment != null &&
            doc.decisionComment!.isNotEmpty)
        ? doc.decisionComment!
        : i18n.t('common.dash');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                if (jobTitle != null)
                  Text(
                    jobTitle,
                    style: TextStyle(fontSize: 12, color: colors.ink2),
                  ),
                Text(
                  i18n.t('docType.${doc.docType}'),
                  style: TextStyle(fontSize: 13, color: colors.ink2),
                ),
                Text(
                  '${i18n.t('docsRh.reason')}: $reason',
                  style: TextStyle(fontSize: 12.5, color: colors.ink3),
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
