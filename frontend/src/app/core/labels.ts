import { DocStatus, LeaveStatus, PresenceStatus } from './models';

export const LEAVE_STATUS_LABEL: Record<LeaveStatus, string> = {
  pending: 'En attente du manager',
  pending_hr: 'En attente RH',
  approved: 'Approuvé',
  rejected: 'Refusé',
};

export const LEAVE_STATUS_CHIP: Record<LeaveStatus, string> = {
  pending: 'warn',
  pending_hr: 'info',
  approved: 'ok',
  rejected: 'bad',
};

export const DOC_STATUS_LABEL: Record<DocStatus, string> = {
  pending: 'En attente',
  processing: 'En rédaction',
  ready: 'Prêt',
  rejected: 'Refusé',
};

export const DOC_STATUS_CHIP: Record<DocStatus, string> = {
  pending: 'warn',
  processing: 'info',
  ready: 'ok',
  rejected: 'bad',
};

export const DOC_TYPE_LABEL: Record<string, string> = {
  work_certificate: 'Attestation de travail',
  salary_certificate: 'Bulletin de paie',
  leave_attestation: 'Attestation de congés',
  other: 'Autre',
};

export const PRESENCE_LABEL: Record<PresenceStatus, string> = {
  on_site: 'Sur site',
  remote: 'Télétravail',
  holiday: 'Congé',
};

export const PRESENCE_CHIP: Record<PresenceStatus, string> = {
  on_site: 'ok',
  remote: 'info',
  holiday: 'warn',
};

export const ROLE_LABEL: Record<string, string> = {
  employee: 'Employé·e',
  lead: 'Chef·fe de projet',
  manager: 'Manager',
  rh: 'RH',
  admin: 'Administrateur·rice',
};

export const ROLE_CHIP: Record<string, string> = {
  employee: 'mut',
  lead: 'info',
  manager: 'info',
  rh: 'warn',
  admin: 'brand',
};

export const CONTRACT_LABEL: Record<string, string> = {
  cdi: 'CDI',
  cdd: 'CDD',
  stage: 'Stage',
  alternance: 'Alternance',
  other: 'Autre',
};
