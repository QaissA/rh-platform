import 'dart:convert';

import 'package:alize_mobile/core/l10n/i18n.dart';
import 'package:flutter_test/flutter_test.dart';

const _frJson = '''
{
  "nav": { "leave": "Congés" },
  "common": { "userN": "Utilisateur #{{id}}" },
  "onlyFr": "Seulement français"
}
''';

const _enJson = '''
{
  "nav": { "leave": "Leave" },
  "common": { "userN": "User #{{id}}" }
}
''';

const _arJson = '''
{
  "nav": { "leave": "الإجازات" },
  "common": { "userN": "مستخدم #{{id}}" }
}
''';

Map<String, Map<String, dynamic>> _dicts() => {
      'fr': jsonDecode(_frJson) as Map<String, dynamic>,
      'en': jsonDecode(_enJson) as Map<String, dynamic>,
      'ar': jsonDecode(_arJson) as Map<String, dynamic>,
    };

I18n _i18n({String initialLang = 'fr'}) =>
    I18n(dicts: _dicts(), initialLang: initialLang);

void main() {
  test('defaults to French and looks up nested keys', () {
    final i18n = _i18n();
    expect(i18n.lang, 'fr');
    expect(i18n.t('nav.leave'), 'Congés');
  });

  test('interpolates {{id}} placeholders', () {
    final i18n = _i18n();
    expect(i18n.t('common.userN', {'id': 3}), 'Utilisateur #3');
  });

  test('dir is rtl for Arabic and ltr otherwise', () {
    expect(_i18n(initialLang: 'ar').dir, 'rtl');
    expect(_i18n().dir, 'ltr');
    expect(_i18n(initialLang: 'en').dir, 'ltr');
  });

  test('locale maps fr/en/ar to fr-FR, en-GB, ar', () {
    expect(_i18n().locale, 'fr-FR');
    expect(_i18n(initialLang: 'en').locale, 'en-GB');
    expect(_i18n(initialLang: 'ar').locale, 'ar');
  });

  test('setLang switches dictionary and dir', () {
    final i18n = _i18n();
    i18n.setLang('en');
    expect(i18n.lang, 'en');
    expect(i18n.t('nav.leave'), 'Leave');
    expect(i18n.dir, 'ltr');
    expect(i18n.locale, 'en-GB');

    i18n.setLang('ar');
    expect(i18n.lang, 'ar');
    expect(i18n.t('nav.leave'), 'الإجازات');
    expect(i18n.dir, 'rtl');
    expect(i18n.t('common.userN', {'id': 3}), 'مستخدم #3');
  });

  test('falls back to French then to the key itself', () {
    final i18n = _i18n(initialLang: 'en');
    expect(i18n.t('onlyFr'), 'Seulement français');
    expect(i18n.t('missing.key'), 'missing.key');
  });

  test('missing interpolation params become empty strings', () {
    final i18n = _i18n();
    expect(i18n.t('common.userN', {}), 'Utilisateur #');
  });
}
