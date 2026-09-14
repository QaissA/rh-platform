import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlizeTheme {
  AlizeTheme._();

  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AlizeColors.radius)),
  );

  static String get uiFontFamily => GoogleFonts.config.allowRuntimeFetching
      ? (GoogleFonts.ibmPlexSans().fontFamily ?? 'Roboto')
      : 'Roboto';

  static String get displayFontFamily => GoogleFonts.config.allowRuntimeFetching
      ? (GoogleFonts.ibmPlexSerif().fontFamily ?? 'Roboto')
      : 'Roboto';

  static ThemeData light() => _build(AlizeColors.light, Brightness.light);

  static ThemeData dark() => _build(AlizeColors.dark, Brightness.dark);

  static ThemeData _build(AlizePalette colors, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.brand,
      brightness: brightness,
    ).copyWith(
      primary: colors.brand,
      onPrimary: const Color(0xFFFFFFFF),
      primaryContainer: colors.brandTint,
      onPrimaryContainer: colors.brandInk,
      secondary: colors.honey,
      onSecondary: const Color(0xFFFFFFFF),
      tertiary: colors.ok,
      onTertiary: const Color(0xFFFFFFFF),
      error: colors.bad,
      onError: const Color(0xFFFFFFFF),
      errorContainer: colors.badTint,
      surface: colors.surface,
      onSurface: colors.ink,
      onSurfaceVariant: colors.ink2,
      outline: colors.line,
      outlineVariant: colors.line2,
      surfaceContainerLowest: colors.paper,
      surfaceContainerLow: colors.surface2,
      surfaceContainerHighest: colors.surface2,
    );

    final textTheme = _textTheme(colors, brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.paper,
      fontFamily: uiFontFamily,
      textTheme: textTheme,
      cardTheme: const CardThemeData(shape: shape),
      dialogTheme: const DialogThemeData(shape: shape),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: shape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: shape),
      ),
    );
  }

  static TextTheme _textTheme(AlizePalette colors, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: uiFontFamily,
    ).textTheme.apply(
      fontFamily: uiFontFamily,
      bodyColor: colors.ink,
      displayColor: colors.ink,
    );
    if (!GoogleFonts.config.allowRuntimeFetching) return base;
    return GoogleFonts.ibmPlexSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.ibmPlexSerif(textStyle: base.displayLarge),
      displayMedium: GoogleFonts.ibmPlexSerif(textStyle: base.displayMedium),
      displaySmall: GoogleFonts.ibmPlexSerif(textStyle: base.displaySmall),
      headlineLarge: GoogleFonts.ibmPlexSerif(textStyle: base.headlineLarge),
      headlineMedium: GoogleFonts.ibmPlexSerif(textStyle: base.headlineMedium),
      headlineSmall: GoogleFonts.ibmPlexSerif(textStyle: base.headlineSmall),
    );
  }
}

/// Disables Material 3's overscroll stretch (a Y-axis scale, worse on Impeller GLES).
class AlizeScrollBehavior extends MaterialScrollBehavior {
  const AlizeScrollBehavior();

  static ScrollBehavior get disabled =>
      const AlizeScrollBehavior().copyWith(overscroll: false);

  static Widget wrap(Widget child) {
    return ScrollConfiguration(
      behavior: disabled,
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (notification) {
          notification.disallowIndicator();
          return true;
        },
        child: child,
      ),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
