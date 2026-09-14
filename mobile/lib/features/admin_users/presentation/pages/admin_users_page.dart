import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/admin_users/presentation/providers/user_admin_providers.dart';
import 'package:alize_mobile/features/admin_users/presentation/user_labels.dart';
import 'package:alize_mobile/features/auth/domain/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _UsersView(),
    );
  }
}

class _UsersView extends ConsumerWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(adminUsersControllerProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      backgroundColor: colors.paper,
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(adminUsersControllerProvider.notifier).reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              i18n.t('users.title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i18n.t('users.help'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: () => context.go('/utilisateurs/new'),
                child: Text(i18n.t('users.new')),
              ),
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
                        i18n.t('users.loading'),
                        style: TextStyle(color: colors.ink2),
                      ),
                    ),
                  ],
                ),
              )
            else if (state.users.isEmpty)
              Text(
                i18n.t('users.help'),
                style: TextStyle(color: colors.ink2),
              )
            else
              ...[
                for (final user in state.users)
                  _UserTile(
                    user: user,
                    colors: colors,
                    i18n: i18n,
                    onOpen: () => context.go('/utilisateurs/${user.id}'),
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.colors,
    required this.i18n,
    required this.onOpen,
  });

  final User user;
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
            userDisplayName(user),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email, style: TextStyle(color: colors.ink3)),
              Text(
                i18n.t('status.role.${user.role}'),
                style: TextStyle(color: colors.ink2, fontSize: 13),
              ),
            ],
          ),
          trailing: Text(i18n.t('common.open')),
          onTap: onOpen,
        ),
      ),
    );
  }
}
