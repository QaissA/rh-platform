import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LangPrefs {
  LangPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const key = 'alize.lang';

  String read() {
    final raw = _prefs.getString(key);
    if (raw == 'fr' || raw == 'en' || raw == 'ar') return raw!;
    return 'fr';
  }

  Future<void> write(String lang) => _prefs.setString(key, lang);
}

class I18n {
  I18n({
    required Map<String, Map<String, dynamic>> dicts,
    String initialLang = 'fr',
    LangPrefs? prefs,
  })  : _dicts = dicts,
        _prefs = prefs,
        _lang = _normalize(initialLang);

  final Map<String, Map<String, dynamic>> _dicts;
  final LangPrefs? _prefs;
  String _lang;

  static const _locales = {'fr': 'fr-FR', 'en': 'en-GB', 'ar': 'ar'};

  String get lang => _lang;

  String get dir => _lang == 'ar' ? 'rtl' : 'ltr';

  String get locale => _locales[_lang] ?? 'fr-FR';

  static Future<I18n> load({
    AssetBundle? bundle,
    LangPrefs? prefs,
    String initialLang = 'fr',
  }) async {
    final b = bundle ?? rootBundle;
    Future<Map<String, dynamic>> decode(String path) async {
      final raw = await b.loadString(path);
      return jsonDecode(raw) as Map<String, dynamic>;
    }

    return I18n(
      dicts: {
        'fr': await decode('assets/i18n/fr.json'),
        'en': await decode('assets/i18n/en.json'),
        'ar': await decode('assets/i18n/ar.json'),
      },
      initialLang: prefs?.read() ?? initialLang,
      prefs: prefs,
    );
  }

  String t(String key, [Map<String, Object>? params]) {
    final raw =
        _lookup(_dicts[_lang], key) ?? _lookup(_dicts['fr'], key) ?? key;
    return _interpolate(raw, params);
  }

  void setLang(String lang) {
    final next = _normalize(lang);
    if (_lang == next) return;
    _lang = next;
    final prefs = _prefs;
    if (prefs != null) unawaited(prefs.write(next));
  }

  static String _normalize(String lang) {
    if (lang == 'fr' || lang == 'en' || lang == 'ar') return lang;
    return 'fr';
  }

  static String? _lookup(Map<String, dynamic>? dict, String path) {
    if (dict == null) return null;
    dynamic cur = dict;
    for (final part in path.split('.')) {
      if (cur is! Map || !cur.containsKey(part)) return null;
      cur = cur[part];
    }
    return cur is String ? cur : null;
  }

  static String _interpolate(String text, Map<String, Object>? params) {
    if (params == null) return text;
    return text.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) {
      final value = params[match.group(1)!];
      return value == null ? '' : '$value';
    });
  }
}
