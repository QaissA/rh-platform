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

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SplashPage shows wave mark and brand wordmark', (tester) async {
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
    await tester.pump();

    expect(find.byType(AlizeWaveMark), findsOneWidget);
    expect(find.text(i18n.t('brand')), findsOneWidget);
  });
}
