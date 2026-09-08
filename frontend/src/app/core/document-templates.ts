import { DOC_TYPE_LABEL } from './labels';

export interface TemplateField {
  key: string;
  label: string;
  type: 'text' | 'textarea' | 'date';
}

export const TEMPLATE_FIELDS: Record<string, TemplateField[]> = {
  work_certificate: [
    { key: 'employee_name', label: 'Nom du collaborateur', type: 'text' },
    { key: 'job_title', label: 'Poste', type: 'text' },
    { key: 'start_date', label: "Date d'entrée", type: 'date' },
    { key: 'company', label: 'Société', type: 'text' },
    { key: 'purpose', label: 'Objet / destinataire', type: 'textarea' },
    { key: 'issued_date', label: "Date d'émission", type: 'date' },
    { key: 'signer', label: 'Signataire', type: 'text' },
  ],
  salary_certificate: [
    { key: 'employee_name', label: 'Nom du collaborateur', type: 'text' },
    { key: 'job_title', label: 'Poste', type: 'text' },
    { key: 'period', label: 'Période', type: 'text' },
    { key: 'net_salary', label: 'Salaire net', type: 'text' },
    { key: 'company', label: 'Société', type: 'text' },
    { key: 'issued_date', label: "Date d'émission", type: 'date' },
    { key: 'signer', label: 'Signataire', type: 'text' },
  ],
  leave_attestation: [
    { key: 'employee_name', label: 'Nom du collaborateur', type: 'text' },
    { key: 'leave_type', label: 'Type de congé', type: 'text' },
    { key: 'leave_start', label: 'Début', type: 'date' },
    { key: 'leave_end', label: 'Fin', type: 'date' },
    { key: 'days', label: 'Nombre de jours', type: 'text' },
    { key: 'company', label: 'Société', type: 'text' },
    { key: 'issued_date', label: "Date d'émission", type: 'date' },
    { key: 'signer', label: 'Signataire', type: 'text' },
  ],
  other: [
    { key: 'employee_name', label: 'Nom du collaborateur', type: 'text' },
    { key: 'title', label: 'Titre du document', type: 'text' },
    { key: 'body', label: 'Contenu', type: 'textarea' },
    { key: 'company', label: 'Société', type: 'text' },
    { key: 'issued_date', label: "Date d'émission", type: 'date' },
    { key: 'signer', label: 'Signataire', type: 'text' },
  ],
};

export function defaultDocFields(
  docType: string,
  employeeName: string,
  note?: string | null,
): Record<string, string> {
  const today = new Date().toISOString().slice(0, 10);
  const base = {
    employee_name: employeeName,
    issued_date: today,
    company: 'Alizé',
    signer: 'Service RH',
  };
  switch (docType) {
    case 'work_certificate':
      return { ...base, job_title: '', start_date: '', purpose: note ?? '' };
    case 'salary_certificate':
      return { ...base, job_title: '', period: note ?? '', net_salary: '' };
    case 'leave_attestation':
      return { ...base, leave_type: note || 'Congés payés', leave_start: '', leave_end: '', days: '' };
    default:
      return { ...base, title: DOC_TYPE_LABEL[docType] ?? 'Document', body: note ?? '' };
  }
}
