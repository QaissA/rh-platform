import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_teams/domain/entities/team_summary.dart';
import 'package:alize_mobile/features/admin_teams/presentation/providers/team_admin_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminTeamsPage extends ConsumerWidget {
  const AdminTeamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _TeamsView(),
    );
  }
}

class _TeamsView extends ConsumerWidget {
  const _TeamsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(adminTeamsControllerProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminTeamsControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              i18n.t('teamsAdmin.title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i18n.t('teamsAdmin.help'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.go('/equipes/new'),
                child: Text(i18n.t('teamsAdmin.new')),
              ),
            ),
            const SizedBox(height: 16),
            if (state.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    i18n.t('teamsAdmin.loading'),
                    style: TextStyle(color: colors.ink2),
                  ),
                ),
              )
            else if (state.teams.isEmpty)
              Text(
                i18n.t('teamsAdmin.empty'),
                style: TextStyle(color: colors.ink2),
              )
            else
              for (final team in state.teams)
                _TeamTile(
                  team: team,
                  colors: colors,
                  i18n: i18n,
                  onOpen: () => context.go('/equipes/${team.id}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({
    required this.team,
    required this.colors,
    required this.i18n,
    required this.onOpen,
  });

  final TeamSummary team;
  final AlizePalette colors;
  final I18nController i18n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AlizeColors.radius),
          border: Border.all(color: colors.line),
        ),
        child: ListTile(
          title: Text(
            team.name,
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink),
          ),
          subtitle: Text(
            '${team.businessUnit?.name ?? i18n.t('common.dash')} · ${team.project?.name ?? i18n.t('teamsAdmin.project')}',
            style: TextStyle(color: colors.ink2),
          ),
          trailing: Text(i18n.t('common.open')),
          onTap: onOpen,
        ),
      ),
    );
  }
}
