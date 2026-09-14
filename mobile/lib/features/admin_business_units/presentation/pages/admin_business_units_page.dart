import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_business_units/domain/entities/business_unit.dart';
import 'package:alize_mobile/features/admin_business_units/presentation/providers/business_unit_admin_providers.dart';
import 'package:alize_mobile/features/team/domain/person_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminBusinessUnitsPage extends ConsumerWidget {
  const AdminBusinessUnitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _UnitsView(),
    );
  }
}

class _UnitsView extends ConsumerWidget {
  const _UnitsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(adminBusinessUnitsControllerProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminBusinessUnitsControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              i18n.t('units.title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i18n.t('units.help'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.go('/business-units/new'),
                child: Text(i18n.t('units.new')),
              ),
            ),
            const SizedBox(height: 16),
            if (state.loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    i18n.t('units.loading'),
                    style: TextStyle(color: colors.ink2),
                  ),
                ),
              )
            else if (state.units.isEmpty)
              Text(
                i18n.t('units.empty'),
                style: TextStyle(color: colors.ink2),
              )
            else
              for (final unit in state.units)
                _UnitTile(
                  unit: unit,
                  colors: colors,
                  i18n: i18n,
                  onOpen: () => context.go('/business-units/${unit.id}'),
                ),
          ],
        ),
      ),
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({
    required this.unit,
    required this.colors,
    required this.i18n,
    required this.onOpen,
  });

  final BusinessUnit unit;
  final AlizePalette colors;
  final I18nController i18n;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final manager = unit.manager;
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
            unit.name,
            style: TextStyle(fontWeight: FontWeight.w700, color: colors.ink),
          ),
          subtitle: Text(
            '${i18n.t('units.manager')}: ${manager == null ? i18n.t('common.dash') : fullName(manager)}',
            style: TextStyle(color: colors.ink2),
          ),
          trailing: Text(i18n.t('common.open')),
          onTap: onOpen,
        ),
      ),
    );
  }
}
