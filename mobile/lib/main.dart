import 'package:alize_mobile/app.dart';
import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final i18n = await I18n.load();
  runApp(
    ProviderScope(
      overrides: [
        i18nProvider.overrideWith((ref) => I18nController(i18n)),
      ],
      child: const AlizeApp(),
    ),
  );
}
