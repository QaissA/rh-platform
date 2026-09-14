import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('light tokens match the Alizé stylesheet', () {
    expect(AlizeColors.radius, 14);
    expect(AlizeColors.light.paper, const Color(0xFFF4F2F8));
    expect(AlizeColors.light.surface, const Color(0xFFFFFFFF));
    expect(AlizeColors.light.ink, const Color(0xFF0E0B14));
    expect(AlizeColors.light.brand, const Color(0xFF460CAD));
    expect(AlizeColors.light.ok, const Color(0xFF2F8F5B));
    expect(AlizeColors.light.warn, const Color(0xFFB77E12));
    expect(AlizeColors.light.bad, const Color(0xFFBB5245));
  });

  test('dark tokens match the Alizé stylesheet', () {
    expect(AlizeColors.dark.paper, const Color(0xFF09080D));
    expect(AlizeColors.dark.surface, const Color(0xFF141220));
    expect(AlizeColors.dark.ink, const Color(0xFFECEAF4));
    expect(AlizeColors.dark.brand, const Color(0xFF8B5CF6));
    expect(AlizeColors.dark.ok, const Color(0xFF46B074));
    expect(AlizeColors.dark.warn, const Color(0xFFD3A03A));
    expect(AlizeColors.dark.bad, const Color(0xFFD66A5B));
  });

  test('light ThemeData uses exact tokens, Material 3, and radius 14', () {
    final theme = AlizeTheme.light();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radius),
    );

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.light);
    expect(theme.scaffoldBackgroundColor, AlizeColors.light.paper);
    expect(theme.colorScheme.primary, AlizeColors.light.brand);
    expect(theme.colorScheme.surface, AlizeColors.light.surface);
    expect(theme.colorScheme.onSurface, AlizeColors.light.ink);
    expect(theme.colorScheme.error, AlizeColors.light.bad);
    expect(theme.colorScheme.tertiary, AlizeColors.light.ok);
    expect(theme.cardTheme.shape, shape);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Roboto');
  });

  test('dark ThemeData uses exact tokens, Material 3, and radius 14', () {
    final theme = AlizeTheme.dark();
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radius),
    );

    expect(theme.useMaterial3, isTrue);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AlizeColors.dark.paper);
    expect(theme.colorScheme.primary, AlizeColors.dark.brand);
    expect(theme.colorScheme.surface, AlizeColors.dark.surface);
    expect(theme.colorScheme.onSurface, AlizeColors.dark.ink);
    expect(theme.colorScheme.error, AlizeColors.dark.bad);
    expect(theme.colorScheme.tertiary, AlizeColors.dark.ok);
    expect(theme.cardTheme.shape, shape);
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Roboto');
  });

  testWidgets('Material 3 Android lists wrap with StretchingOverscrollIndicator', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [for (var i = 0; i < 20; i++) Text('item $i')],
        ),
      ),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsOneWidget);
  });

  testWidgets('AlizeScrollBehavior.wrap does not stretch scrollables on Y', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: AlizeScrollBehavior.disabled,
        builder: (context, child) => AlizeScrollBehavior.wrap(
          child ?? const SizedBox.shrink(),
        ),
        home: ListView(
          children: [for (var i = 0; i < 20; i++) Text('item $i')],
        ),
      ),
    );

    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pump();

    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
  });
}
