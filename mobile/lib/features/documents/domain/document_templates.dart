import 'package:alize_mobile/core/format/dates.dart';

enum TemplateFieldType { text, textarea, date }

class TemplateField {
  const TemplateField({required this.key, required this.type});

  final String key;
  final TemplateFieldType type;
}

const templateFields = <String, List<TemplateField>>{
  'work_certificate': [
    TemplateField(key: 'employee_name', type: TemplateFieldType.text),
    TemplateField(key: 'job_title', type: TemplateFieldType.text),
    TemplateField(key: 'start_date', type: TemplateFieldType.date),
    TemplateField(key: 'company', type: TemplateFieldType.text),
    TemplateField(key: 'purpose', type: TemplateFieldType.textarea),
    TemplateField(key: 'issued_date', type: TemplateFieldType.date),
    TemplateField(key: 'signer', type: TemplateFieldType.text),
  ],
  'salary_certificate': [
    TemplateField(key: 'employee_name', type: TemplateFieldType.text),
    TemplateField(key: 'job_title', type: TemplateFieldType.text),
    TemplateField(key: 'period', type: TemplateFieldType.text),
    TemplateField(key: 'net_salary', type: TemplateFieldType.text),
    TemplateField(key: 'company', type: TemplateFieldType.text),
    TemplateField(key: 'issued_date', type: TemplateFieldType.date),
    TemplateField(key: 'signer', type: TemplateFieldType.text),
  ],
  'leave_attestation': [
    TemplateField(key: 'employee_name', type: TemplateFieldType.text),
    TemplateField(key: 'leave_type', type: TemplateFieldType.text),
    TemplateField(key: 'leave_start', type: TemplateFieldType.date),
    TemplateField(key: 'leave_end', type: TemplateFieldType.date),
    TemplateField(key: 'days', type: TemplateFieldType.text),
    TemplateField(key: 'company', type: TemplateFieldType.text),
    TemplateField(key: 'issued_date', type: TemplateFieldType.date),
    TemplateField(key: 'signer', type: TemplateFieldType.text),
  ],
  'other': [
    TemplateField(key: 'employee_name', type: TemplateFieldType.text),
    TemplateField(key: 'title', type: TemplateFieldType.text),
    TemplateField(key: 'body', type: TemplateFieldType.textarea),
    TemplateField(key: 'company', type: TemplateFieldType.text),
    TemplateField(key: 'issued_date', type: TemplateFieldType.date),
    TemplateField(key: 'signer', type: TemplateFieldType.text),
  ],
};

Map<String, String> defaultDocFields({
  required String docType,
  required String employeeName,
  String? note,
  required String Function(String key, [Map<String, Object>? params]) t,
}) {
  final today = isoDate(DateTime.now());
  final base = <String, String>{
    'employee_name': employeeName,
    'issued_date': today,
    'company': 'Alizé',
    'signer': t('docSheet.hrSigner'),
  };
  switch (docType) {
    case 'work_certificate':
      return {
        ...base,
        'job_title': '',
        'start_date': '',
        'purpose': note ?? '',
      };
    case 'salary_certificate':
      return {
        ...base,
        'job_title': '',
        'period': note ?? '',
        'net_salary': '',
      };
    case 'leave_attestation':
      return {
        ...base,
        'leave_type': note == null || note.isEmpty
            ? t('leave.types.paid')
            : note,
        'leave_start': '',
        'leave_end': '',
        'days': '',
      };
    default:
      return {
        ...base,
        'title': t('docType.$docType') == 'docType.$docType'
            ? t('common.document')
            : t('docType.$docType'),
        'body': note ?? '',
      };
  }
}
