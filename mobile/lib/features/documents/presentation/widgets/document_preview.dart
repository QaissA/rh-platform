import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/core/theme/alize_theme.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/presentation/document_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DocumentPreview extends ConsumerWidget {
  const DocumentPreview({super.key, required this.doc});

  final DocumentRequest doc;

  String _f(String key) => doc.fields?[key] ?? '';

  bool _isDateKey(String key) =>
      key.endsWith('_date') || key == 'leave_start' || key == 'leave_end';

  String _pretty(I18nController i18n, String key) {
    final raw = _f(key);
    if (raw.isEmpty) return i18n.t('docSheet.blank');
    return _isDateKey(key) ? formatDay(raw) : raw;
  }

  String _typeLabel(I18nController i18n) {
    final title = _f('title');
    if (title.isNotEmpty) return title;
    return i18n.t('docType.${doc.docType}');
  }

  String _issued(I18nController i18n) {
    final raw = _f('issued_date');
    return raw.isEmpty ? '' : formatDay(raw);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final colors = documentPaletteOf(context);
    final issued = _issued(i18n);
    final serif = AlizeTheme.displayFontFamily;
    final sans = AlizeTheme.uiFontFamily;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: serif,
            color: colors.ink,
            fontSize: 16,
            height: 1.65,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.waves, color: colors.brand, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pretty(i18n, 'company'),
                          style: TextStyle(
                            fontFamily: serif,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                          ),
                        ),
                        Text(
                          i18n.t('docSheet.hr'),
                          style: TextStyle(
                            fontFamily: sans,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                            color: colors.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                _typeLabel(i18n),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: serif,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 22),
              ..._body(i18n, colors),
              const SizedBox(height: 28),
              Text(i18n.t('docSheet.closing')),
              const SizedBox(height: 48),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      i18n.t(
                        'docSheet.issuedOn',
                        {'date': issued.isEmpty ? i18n.t('docSheet.blank') : issued},
                      ),
                      style: TextStyle(
                        fontFamily: sans,
                        fontSize: 14,
                        color: colors.ink2,
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      _pretty(i18n, 'signer'),
                      style: TextStyle(
                        fontFamily: serif,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(I18nController i18n, AlizePalette colors) {
    Widget name() => Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            _pretty(i18n, 'employee_name'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AlizeTheme.displayFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.ink,
            ),
          ),
        );

    switch (doc.docType) {
      case 'work_certificate':
        final start = _f('start_date');
        final purpose = _f('purpose');
        return [
          Text(
            i18n.t('docSheet.weCertify', {'company': _pretty(i18n, 'company')}),
          ),
          name(),
          Text(
            '${i18n.t('docSheet.occupies', {'title': _pretty(i18n, 'job_title')})}'
            '${start.isEmpty ? '' : ' ${i18n.t('docSheet.since', {'date': _pretty(i18n, 'start_date')})}'}.',
          ),
          if (purpose.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                i18n.t('docSheet.issuedFor', {'purpose': purpose}),
              ),
            ),
        ];
      case 'salary_certificate':
        return [
          Text(
            i18n.t('docSheet.weCertify', {'company': _pretty(i18n, 'company')}),
          ),
          name(),
          Text(
            i18n.t(
              'docSheet.occupying',
              {
                'title': _pretty(i18n, 'job_title'),
                'period': _pretty(i18n, 'period'),
                'salary': _pretty(i18n, 'net_salary'),
              },
            ),
          ),
        ];
      case 'leave_attestation':
        final days = _f('days');
        return [
          Text(
            i18n.t('docSheet.weCertify', {'company': _pretty(i18n, 'company')}),
          ),
          name(),
          Text(
            '${i18n.t('docSheet.hadLeave', {
                  'type': _pretty(i18n, 'leave_type'),
                  'start': _pretty(i18n, 'leave_start'),
                  'end': _pretty(i18n, 'leave_end'),
                })}'
            '${days.isEmpty ? '' : i18n.t('docSheet.daysWorth', {'days': days})}.',
          ),
        ];
      default:
        final body = _f('body');
        return [
          name(),
          Text(body.isEmpty ? i18n.t('docSheet.blank') : body),
        ];
    }
  }
}
