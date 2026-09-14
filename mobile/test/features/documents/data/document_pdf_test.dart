import 'package:alize_mobile/features/documents/data/document_pdf.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_request.dart';
import 'package:alize_mobile/features/documents/domain/entities/document_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String _t(String key, [Map<String, Object>? params]) {
  const fr = {
    'common.document': 'Document',
    'docType.work_certificate': 'Attestation de travail',
    'docSheet.hr': 'Ressources humaines',
    'docSheet.weCertify': 'Nous soussignés, {{company}}, certifions que',
    'docSheet.occupies': 'occupe le poste de {{title}}',
    'docSheet.since': 'depuis le {{date}}',
    'docSheet.issuedFor': 'La présente attestation est délivrée pour : {{purpose}}.',
    'docSheet.closing': 'Fait pour valoir ce que de droit.',
    'docSheet.issuedOn': 'À la date du {{date}}',
    'docSheet.blank': '………………',
  };
  var text = fr[key] ?? key;
  if (params == null) return text;
  for (final entry in params.entries) {
    text = text.replaceAll('{{${entry.key}}}', '${entry.value}');
  }
  return text;
}

void main() {
  test('buildPdf returns non-empty bytes for a work_certificate', () async {
    const doc = DocumentRequest(
      id: 42,
      userId: 7,
      docType: 'work_certificate',
      status: DocumentStatus.ready,
      fields: {
        'employee_name': 'Ada Lovelace',
        'job_title': 'Ingénieure',
        'start_date': '2020-03-01',
        'company': 'Alizé',
        'purpose': 'banque',
        'issued_date': '2026-09-09',
        'signer': 'Service RH',
      },
    );

    final bytes = await buildPdf(doc, _t);

    expect(bytes, isNotEmpty);
  });

  testWidgets(
    'buildPdf returns non-empty bytes for an Arabic work_certificate',
    (tester) async {
      const doc = DocumentRequest(
        id: 42,
        userId: 7,
        docType: 'work_certificate',
        status: DocumentStatus.ready,
        fields: {
          'employee_name': 'عادل',
          'job_title': 'مهندس',
          'start_date': '2020-03-01',
          'company': 'أليزي',
          'purpose': 'بنك',
          'issued_date': '2026-09-09',
          'signer': 'مصلحة الموارد البشرية',
        },
      );

      final bytes = await buildPdf(doc, _ar);
      expect(bytes, isNotEmpty);

      final font = await rootBundle.load(
        'assets/fonts/IBMPlexSansArabic-Regular.ttf',
      );
      expect(font.lengthInBytes, greaterThan(1000));
    },
  );
}

String _ar(String key, [Map<String, Object>? params]) {
  const ar = {
    'common.document': 'مستند',
    'docType.work_certificate': 'شهادة عمل',
    'docSheet.hr': 'الموارد البشرية',
    'docSheet.weCertify': 'نحن الموقعون أدناه، {{company}}، نشهد أن',
    'docSheet.occupies': 'يشغل منصب {{title}}',
    'docSheet.since': 'منذ {{date}}',
    'docSheet.issuedFor': 'تُسلَّم هذه الشهادة من أجل: {{purpose}}.',
    'docSheet.closing': 'حرّر للعمل به عند الاقتضاء.',
    'docSheet.issuedOn': 'بتاريخ {{date}}',
    'docSheet.blank': '………………',
  };
  var text = ar[key] ?? key;
  if (params == null) return text;
  for (final entry in params.entries) {
    text = text.replaceAll('{{${entry.key}}}', '${entry.value}');
  }
  return text;
}
