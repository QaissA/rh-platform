import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_business_units/presentation/providers/business_unit_admin_providers.dart';
import 'package:alize_mobile/features/admin_projects/domain/entities/project.dart';
import 'package:alize_mobile/features/admin_projects/presentation/providers/project_admin_providers.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminProjectsPage extends ConsumerWidget {
  const AdminProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _ProjectsView(),
    );
  }
}

class _ProjectsView extends ConsumerWidget {
  const _ProjectsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(adminProjectsControllerProvider);
    final units = ref.watch(adminBusinessUnitsControllerProvider).units;
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminProjectsControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              i18n.t('projects.title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i18n.t('projects.help'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              key: ValueKey(state.filterBuId),
              initialValue: state.filterBuId,
              decoration: InputDecoration(labelText: i18n.t('projects.filterBu')),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(i18n.t('common.all')),
                ),
                for (final unit in units)
                  DropdownMenuItem(value: unit.id, child: Text(unit.name)),
              ],
              onChanged: (value) => ref
                  .read(adminProjectsControllerProvider.notifier)
                  .setFilter(value),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.go('/projets/new'),
                child: Text(i18n.t('projects.new')),
              ),
            ),
            const SizedBox(height: 16),
            if (state.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    i18n.t('projects.loading'),
                    style: TextStyle(color: colors.ink2),
                  ),
                ),
              )
            else if (state.projects.isEmpty)
              Text(
                i18n.t('projects.empty'),
                style: TextStyle(color: colors.ink2),
              )
            else
              for (final project in state.projects)
                _ProjectTile(
                  project: project,
                  colors: colors,
                  i18n: i18n,
                  onOpen: () => context.go('/projets/${project.id}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.colors,
    required this.i18n,
    required this.onOpen,
  });

  final Project project;
  final AlizePalette colors;
  final I18nController i18n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final lead = project.lead;
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
            project.name,
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink),
          ),
          subtitle: Text(
            '${project.businessUnit?.name ?? i18n.t('common.dash')} · ${i18n.t('projects.lead')}: ${lead == null ? i18n.t('common.dash') : fullName(lead)}',
            style: TextStyle(color: colors.ink2),
          ),
          trailing: Text(i18n.t('common.open')),
          onTap: onOpen,
        ),
      ),
    );
  }
}
