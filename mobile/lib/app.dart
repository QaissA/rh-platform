import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/router/app_router.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlizeApp extends ConsumerWidget {
  const AlizeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final themeController = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: i18n.t('brand'),
      theme: AlizeTheme.light(),
      darkTheme: AlizeTheme.dark(),
      themeMode: themeController.themeMode,
      scrollBehavior: AlizeScrollBehavior.disabled,
      locale: Locale(i18n.lang),
      routerConfig: router,
      builder: (context, child) {
        return AlizeScrollBehavior.wrap(
          Directionality(
            textDirection:
                i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
