import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LangSwitcher extends ConsumerWidget {
  const LangSwitcher({super.key});

  static const langs = ['fr', 'en', 'ar'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Semantics(
      container: true,
      label: i18n.t('lang.label'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(999),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final lang in langs)
                _LangButton(
                  lang: lang,
                  selected: i18n.lang == lang,
                  colors: colors,
                  onPressed: () => i18n.setLang(lang),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.lang,
    required this.selected,
    required this.colors,
    required this.onPressed,
  });

  final String lang;
  final bool selected;
  final AlizePalette colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? colors.brandTint : Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Text(
            lang.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: selected ? colors.brandInk : colors.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
