import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class I18nController extends ChangeNotifier {
  I18nController(this._i18n);

  final I18n _i18n;

  String t(String key, [Map<String, Object>? params]) => _i18n.t(key, params);

  String get lang => _i18n.lang;

  String get dir => _i18n.dir;

  String get locale => _i18n.locale;

  void setLang(String lang) {
    final previous = _i18n.lang;
    _i18n.setLang(lang);
    if (_i18n.lang != previous) notifyListeners();
  }
}

final i18nProvider = ChangeNotifierProvider<I18nController>(
  (ref) => throw UnimplementedError('Override i18nProvider'),
);
