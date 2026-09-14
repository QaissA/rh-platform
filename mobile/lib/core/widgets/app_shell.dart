import 'dart:async';

import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/core/theme/theme_controller.dart';
import 'package:alize_mobile/core/widgets/lang_switcher.dart';
import 'package:alize_mobile/features/chat/presentation/providers/chat_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/inbox_badge_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/providers/notification_providers.dart';
import 'package:alize_mobile/features/notifications/presentation/widgets/notifications_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  static const floatingNavBarKey = Key('floating-nav-bar');

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tick();
    });
    _startPoll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tick();
      _startPoll();
    } else {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _tick();
    });
  }

  void _tick() {
    ref.read(notificationsControllerProvider.notifier).load();
    ref.read(inboxBadgeProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final path = GoRouterState.of(context).uri.path;
    final title = _pageTitle(i18n, path);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = ref.watch(
      chatControllerProvider.select((s) => s.unreadTotal),
    );
    final queue = ref.watch(
      inboxBadgeProvider.select((s) => s.leaveQueue + s.docQueue),
    );

    final colors = isDark ? AlizeColors.dark : AlizeColors.light;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          const LangSwitcher(),
          IconButton(
            tooltip: i18n.t('nav.theme'),
            onPressed: () => ref.read(themeControllerProvider).toggle(),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const NotificationsBell(),
        ],
      ),
      body: widget.navigationShell,
      backgroundColor: colors.paper,
      bottomNavigationBar: _FloatingNavBar(
        colors: colors,
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: i18n.t('nav.dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_outlined),
            selectedIcon: const Icon(Icons.event),
            label: i18n.t('nav.leave'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups),
            label: i18n.t('nav.team'),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: i18n.t('nav.messages'),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: queue > 0,
              label: Text('$queue'),
              child: const Icon(Icons.menu),
            ),
            selectedIcon: Badge(
              isLabelVisible: queue > 0,
              label: Text('$queue'),
              child: const Icon(Icons.menu),
            ),
            label: _moreLabel(i18n),
          ),
        ],
      ),
    );
  }

  static String _pageTitle(I18nController i18n, String path) {
    final key = path.split('/').where((part) => part.isNotEmpty).firstOrNull ??
        'dashboard';
    final title = i18n.t('page.$key.title');
    return title == 'page.$key.title' ? i18n.t('brand') : title;
  }

  static String _moreLabel(I18nController i18n) {
    final translated = i18n.t('nav.more');
    return translated == 'nav.more' ? 'More' : translated;
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.colors,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  static const _radius = 24.0;

  final AlizePalette colors;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
      child: DecoratedBox(
        key: AppShell.floatingNavBarKey,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: colors.line),
          boxShadow: [
            BoxShadow(
              color: colors.ink.withValues(alpha: isDark ? 0.35 : 0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 56,
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                indicatorColor: colors.brandTint,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AlizeColors.radius),
                ),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    size: 24,
                    color: selected ? colors.brandInk : colors.ink2,
                  );
                }),
              ),
              child: NavigationBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: destinations,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
