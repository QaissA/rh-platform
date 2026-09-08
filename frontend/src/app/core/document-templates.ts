export interface TemplateField {
  key: string;
  type: 'text' | 'textarea' | 'date';
}

export const TEMPLATE_FIELDS: Record<string, TemplateField[]> = {
  work_certificate: [
    { key: 'employee_name', type: 'text' },
    { key: 'job_title', type: 'text' },
    { key: 'start_date', type: 'date' },
    { key: 'company', type: 'text' },
    { key: 'purpose', type: 'textarea' },
    { key: 'issued_date', type: 'date' },
    { key: 'signer', type: 'text' },
  ],
  salary_certificate: [
    { key: 'employee_name', type: 'text' },
    { key: 'job_title', type: 'text' },
    { key: 'period', type: 'text' },
    { key: 'net_salary', type: 'text' },
    { key: 'company', type: 'text' },
    { key: 'issued_date', type: 'date' },
    { key: 'signer', type: 'text' },
  ],
  leave_attestation: [
    { key: 'employee_name', type: 'text' },
    { key: 'leave_type', type: 'text' },
    { key: 'leave_start', type: 'date' },
    { key: 'leave_end', type: 'date' },
    { key: 'days', type: 'text' },
    { key: 'company', type: 'text' },
    { key: 'issued_date', type: 'date' },
    { key: 'signer', type: 'text' },
  ],
  other: [
    { key: 'employee_name', type: 'text' },
    { key: 'title', type: 'text' },
    { key: 'body', type: 'textarea' },
    { key: 'company', type: 'text' },
    { key: 'issued_date', type: 'date' },
    { key: 'signer', type: 'text' },
  ],
};

export function defaultDocFields(
  docType: string,
  employeeName: string,
  note: string | null | undefined,
  t: (key: string, params?: Record<string, string | number>) => string,
): Record<string, string> {
  const today = new Date().toISOString().slice(0, 10);
  const base = {
    employee_name: employeeName,
    issued_date: today,
    company: 'Alizé',
    signer: t('docSheet.hrSigner'),
  };
  switch (docType) {
    case 'work_certificate':
      return { ...base, job_title: '', start_date: '', purpose: note ?? '' };
    case 'salary_certificate':
      return { ...base, job_title: '', period: note ?? '', net_salary: '' };
    case 'leave_attestation':
      return { ...base, leave_type: note || t('leave.types.paid'), leave_start: '', leave_end: '', days: '' };
    default:
      return { ...base, title: t(`docType.${docType}`) || t('common.document'), body: note ?? '' };
  }
}
