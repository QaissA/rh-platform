import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/router/roles.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  static const logoutTileKey = Key('more-logout');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final auth = ref.watch(authProvider);
    final role = auth is AuthSignedIn ? auth.session.user.role : '';
    final badges = ref.watch(inboxBadgeProvider);
    final unread = ref.watch(
      chatControllerProvider.select((s) => s.unreadTotal),
    );
    final error = Theme.of(context).colorScheme.error;

    return ListView(
      children: [
        _SectionLabel(i18n.t('nav.space')),
        ListTile(
          leading: const Icon(Icons.home_outlined),
          title: Text(i18n.t('nav.dashboard')),
          onTap: () => context.go('/dashboard'),
        ),
        ListTile(
          leading: const Icon(Icons.event_outlined),
          title: Text(i18n.t('nav.leave')),
          onTap: () => context.go('/conges'),
        ),
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: Text(i18n.t('nav.team')),
          onTap: () => context.go('/equipe'),
        ),
        ListTile(
          leading: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          title: Text(i18n.t('nav.messages')),
          onTap: () => context.go('/messages'),
        ),
        if (isManager(role))
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(i18n.t('nav.leaveReview')),
            trailing: badges.leaveQueue > 0
                ? Badge(label: Text('${badges.leaveQueue}'))
                : null,
            onTap: () => context.go('/validation-conges'),
          ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(i18n.t('nav.documents')),
          onTap: () => context.go('/documents'),
        ),
        if (isRh(role)) ...[
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: Text(i18n.t('nav.documentsRh')),
            trailing: badges.docQueue > 0
                ? Badge(label: Text('${badges.docQueue}'))
                : null,
            onTap: () => context.go('/documents-rh'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined),
            title: Text(i18n.t('nav.dossiers')),
            onTap: () => context.go('/dossiers'),
          ),
        ],
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(i18n.t('nav.settings')),
          onTap: () => context.go('/parametres'),
        ),
        if (isAdmin(role)) ...[
          _SectionLabel(i18n.t('nav.admin')),
          ListTile(
            leading: const Icon(Icons.apartment_outlined),
            title: Text(i18n.t('nav.units')),
            onTap: () => context.go('/business-units'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(i18n.t('nav.projects')),
            onTap: () => context.go('/projets'),
          ),
          ListTile(
            leading: const Icon(Icons.groups_2_outlined),
            title: Text(i18n.t('nav.teams')),
            onTap: () => context.go('/equipes'),
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: Text(i18n.t('nav.users')),
            onTap: () => context.go('/utilisateurs'),
          ),
        ],
        const Divider(height: 24),
        ListTile(
          key: MorePage.logoutTileKey,
          leading: Icon(Icons.logout, color: error),
          title: Text(
            i18n.t('nav.logout'),
            style: TextStyle(color: error),
          ),
          onTap: () => ref.read(authProvider.notifier).logout(),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
