import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _regularFontAsset = 'assets/fonts/IBMPlexSansArabic-Regular.ttf';
const _boldFontAsset = 'assets/fonts/IBMPlexSansArabic-Bold.ttf';
final _arabicGlyphs = RegExp(r'[\u0600-\u06FF]');

typedef DocumentTranslate = String Function(
  String key, [
  Map<String, Object>? params,
]);

Future<Uint8List> buildPdf(
  DocumentRequest doc,
  DocumentTranslate t,
) async {
  final theme = await _pdfTheme();
  final rtl = _isRtl(doc, t);
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(44, 40, 44, 48),
      theme: theme,
      build: (context) {
        return pw.Directionality(
          textDirection:
              rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                _pretty(doc, t, 'company'),
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                t('docSheet.hr'),
                style: const pw.TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  color: PdfColor.fromInt(0x6B6578),
                ),
              ),
              pw.SizedBox(height: 28),
              pw.Text(
                _titleOf(doc, t),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 22),
              ..._body(doc, t),
              pw.SizedBox(height: 12),
              pw.Text(
                t('docSheet.closing'),
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 48),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      t('docSheet.issuedOn', {'date': _issued(doc, t)}),
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 36),
                    pw.Text(
                      _pretty(doc, t, 'signer'),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
  return pdf.save();
}

Future<pw.ThemeData> _pdfTheme() async {
  try {
    final regular = await rootBundle.load(_regularFontAsset);
    final bold = await rootBundle.load(_boldFontAsset);
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  } catch (_) {
    return pw.ThemeData.withFont(
      base: pw.Font.times(),
      bold: pw.Font.timesBold(),
    );
  }
}

bool _isRtl(DocumentRequest doc, DocumentTranslate t) {
  final samples = [
    t('docSheet.hr'),
    t('docSheet.closing'),
    t('docType.${doc.docType}'),
    ...?doc.fields?.values,
  ];
  return samples.any(_arabicGlyphs.hasMatch);
}

String documentFileName(DocumentRequest doc, DocumentTranslate t) {
  var slug = t('docType.${doc.docType}');
  if (slug.isEmpty || slug == 'docType.${doc.docType}') {
    slug = t('common.document');
  }
  slug = _asciiSlug(slug);
  if (slug.isEmpty) slug = 'document';
  return '$slug-${doc.id}.pdf';
}

String _f(DocumentRequest doc, String key) => doc.fields?[key] ?? '';

bool _isDateKey(String key) =>
    key.endsWith('_date') || key == 'leave_start' || key == 'leave_end';

String _pretty(DocumentRequest doc, DocumentTranslate t, String key) {
  final raw = _f(doc, key);
  if (raw.isEmpty) return t('docSheet.blank');
  return _isDateKey(key) ? formatDay(raw) : raw;
}

String _titleOf(DocumentRequest doc, DocumentTranslate t) {
  final title = _f(doc, 'title');
  if (title.isNotEmpty) return title;
  final type = t('docType.${doc.docType}');
  if (type != 'docType.${doc.docType}') return type;
  return t('common.document');
}

String _issued(DocumentRequest doc, DocumentTranslate t) {
  final raw = _f(doc, 'issued_date');
  if (raw.isEmpty) return t('docSheet.blank');
  return formatDay(raw);
}

List<pw.Widget> _body(DocumentRequest doc, DocumentTranslate t) {
  pw.Widget name() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 18),
        child: pw.Text(
          _pretty(doc, t, 'employee_name'),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
      );

  const bodyStyle = pw.TextStyle(fontSize: 16);
  switch (doc.docType) {
    case 'work_certificate':
      final start = _f(doc, 'start_date');
      final purpose = _f(doc, 'purpose');
      return [
        pw.Text(
          t('docSheet.weCertify', {'company': _pretty(doc, t, 'company')}),
          style: bodyStyle,
        ),
        name(),
        pw.Text(
          '${t('docSheet.occupies', {'title': _pretty(doc, t, 'job_title')})}'
          '${start.isEmpty ? '' : ' ${t('docSheet.since', {'date': _pretty(doc, t, 'start_date')})}'}.',
          style: bodyStyle,
        ),
        if (purpose.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              t('docSheet.issuedFor', {'purpose': purpose}),
              style: bodyStyle,
            ),
          ),
      ];
    case 'salary_certificate':
      return [
        pw.Text(
          t('docSheet.weCertify', {'company': _pretty(doc, t, 'company')}),
          style: bodyStyle,
        ),
        name(),
        pw.Text(
          t('docSheet.occupying', {
            'title': _pretty(doc, t, 'job_title'),
            'period': _pretty(doc, t, 'period'),
            'salary': _pretty(doc, t, 'net_salary'),
          }),
          style: bodyStyle,
        ),
      ];
    case 'leave_attestation':
      final days = _f(doc, 'days');
      return [
        pw.Text(
          t('docSheet.weCertify', {'company': _pretty(doc, t, 'company')}),
          style: bodyStyle,
        ),
        name(),
        pw.Text(
          '${t('docSheet.hadLeave', {
                'type': _pretty(doc, t, 'leave_type'),
                'start': _pretty(doc, t, 'leave_start'),
                'end': _pretty(doc, t, 'leave_end'),
              })}'
          '${days.isEmpty ? '' : t('docSheet.daysWorth', {'days': days})}.',
          style: bodyStyle,
        ),
      ];
    default:
      final body = _f(doc, 'body');
      return [
        name(),
        pw.Text(
          body.isEmpty ? t('docSheet.blank') : body,
          style: bodyStyle,
        ),
      ];
  }
}

String _asciiSlug(String input) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñ';
  const to = 'aaaaaaeeeeiiiiooooouuuuyycn';
  final folded = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final i = from.indexOf(ch);
    folded.write(i >= 0 ? to[i] : ch);
  }
  return folded
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
