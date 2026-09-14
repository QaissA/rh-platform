import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/splash/presentation/pages/splash_page.dart';
import 'package:alize_mobile/features/splash/presentation/widgets/alize_wave_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _UnknownAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthUnknown();
}

Future<void> _pumpSplash(WidgetTester tester) async {
  final i18n = await I18n.load();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        i18nProvider.overrideWith((ref) => I18nController(i18n)),
        authProvider.overrideWith(() => _UnknownAuth()),
      ],
      child: MaterialApp(
        theme: AlizeTheme.light(),
        home: const SplashPage(),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SplashPage shows wave mark and brand wordmark', (tester) async {
    await _pumpSplash(tester);
    await tester.pump();

    expect(find.byType(AlizeWaveMark), findsOneWidget);
    final i18n = await I18n.load();
    expect(find.text(i18n.t('brand')), findsOneWidget);

    // Let animation complete so ticker is released
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('wave mark animates from empty toward drawn', (tester) async {
    await _pumpSplash(tester);
    await tester.pump(); // frame 0
    final before = tester.widget<AlizeWaveMark>(find.byType(AlizeWaveMark));
    expect(before.progress, lessThan(0.2));

    await tester.pump(const Duration(milliseconds: 600));
    final mid = tester.widget<AlizeWaveMark>(find.byType(AlizeWaveMark));
    expect(mid.progress, greaterThan(before.progress));

    // Let animation complete so ticker is released
    await tester.pump(const Duration(seconds: 3));
  });
}
