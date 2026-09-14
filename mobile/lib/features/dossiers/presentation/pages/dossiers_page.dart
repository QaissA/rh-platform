import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/dossiers/presentation/providers/dossier_providers.dart';
import 'package:alize_mobile/features/team/domain/entities/team_member.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DossiersPage extends ConsumerWidget {
  const DossiersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _DossiersView(),
    );
  }
}

class _DossiersView extends ConsumerWidget {
  const _DossiersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(dossiersControllerProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(dossiersControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              i18n.t('dossiers.title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i18n.t('dossiers.help'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
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
                        i18n.t('common.loading'),
                        style: TextStyle(color: colors.ink2),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              if (state.pending.isNotEmpty) ...[
                _Card(
                  colors: colors,
                  warn: true,
                  title: i18n.t('dossiers.jobRequests'),
                  child: Column(
                    children: [
                      for (final user in state.pending)
                        _PendingRow(
                          user: user,
                          colors: colors,
                          i18n: i18n,
                          busy: state.busyId == user.id,
                          onAccept: () => _accept(context, ref, user),
                          onReject: () => _reject(context, ref, user),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _Card(
                colors: colors,
                child: Column(
                  children: [
                    for (final user in state.users)
                      _DossierRow(
                        user: user,
                        colors: colors,
                        i18n: i18n,
                        onOpen: () => context.go('/dossiers/${user.id}'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    TeamMember user,
  ) async {
    final result =
        await ref.read(dossiersControllerProvider.notifier).acceptJobTitle(user);
    if (!context.mounted) return;
    final i18n = ref.read(i18nProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isOk
              ? i18n.t('dossiers.jobAccepted', {'name': memberName(user)})
              : i18n.t('dossiers.acceptFail'),
        ),
      ),
    );
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    TeamMember user,
  ) async {
    final result =
        await ref.read(dossiersControllerProvider.notifier).rejectJobTitle(user);
    if (!context.mounted) return;
    final i18n = ref.read(i18nProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isOk
              ? i18n.t('dossiers.rejectedFor', {'name': memberName(user)})
              : i18n.t('dossiers.rejectFail'),
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({
    required this.user,
    required this.colors,
    required this.i18n,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final TeamMember user;
  final AlizePalette colors;
  final I18nController i18n;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final title = jobTitleOf(user);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memberName(user),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          if (title != null)
            Text(title, style: TextStyle(fontSize: 12, color: colors.ink2)),
          Text(
            i18n.t('dossiers.requestMeta', {
              'pending': user.pendingJobTitle ?? '',
              'current': title ?? i18n.t('common.dash'),
            }),
            style: TextStyle(fontSize: 12.5, color: colors.ink3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: busy ? null : onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(i18n.t('dossiers.accept')),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: busy ? null : onReject,
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

class _DossierRow extends StatelessWidget {
  const _DossierRow({
    required this.user,
    required this.colors,
    required this.i18n,
    required this.onOpen,
  });

  final TeamMember user;
  final AlizePalette colors;
  final I18nController i18n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final title = jobTitleOf(user);
    final pending = (user.pendingJobTitle ?? '').trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName(user),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                if (title != null)
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: colors.ink2),
                  ),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12.5, color: colors.ink3),
                ),
                const SizedBox(height: 4),
                Text(
                  '${i18n.t('dossiers.job')}: ${title ?? i18n.t('common.dash')}',
                  style: TextStyle(fontSize: 13, color: colors.ink2),
                ),
                Text(
                  '${i18n.t('dossiers.account')}: ${i18n.t('status.role.${user.role}')}',
                  style: TextStyle(fontSize: 13, color: colors.ink2),
                ),
                if (pending)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      i18n.t('dossiers.requestChip'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.warn,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: Text(i18n.t('common.open')),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.colors,
    required this.child,
    this.title,
    this.warn = false,
  });

  final AlizePalette colors;
  final String? title;
  final bool warn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: warn ? colors.warn : colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 10),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
