import { DocStatus, LeaveStatus, PresenceStatus } from './models';

export const LEAVE_STATUS_CHIP: Record<LeaveStatus, string> = {
  pending: 'warn',
  pending_hr: 'info',
  approved: 'ok',
  rejected: 'bad',
};

export const DOC_STATUS_CHIP: Record<DocStatus, string> = {
  pending: 'warn',
  processing: 'info',
  ready: 'ok',
  rejected: 'bad',
  cancelled: 'mut',
};

export const PRESENCE_CHIP: Record<PresenceStatus, string> = {
  on_site: 'ok',
  remote: 'info',
  holiday: 'warn',
};

export const ROLE_CHIP: Record<string, string> = {
  employee: 'mut',
  lead: 'info',
  manager: 'info',
  rh: 'warn',
  admin: 'brand',
};

export const CONTRACT_TYPES = ['cdi', 'cdd', 'stage', 'alternance', 'other'] as const;

const LEAVE_TYPE_ALIASES: Record<string, string> = {
  paid: 'paid',
  rtt: 'rtt',
  unpaid: 'unpaid',
  family: 'family',
  'Congés payés': 'paid',
  'Paid leave': 'paid',
  Congés: 'paid',
  Leave: 'paid',
  إجازة: 'paid',
  'إجازة مدفوعة': 'paid',
  RTT: 'rtt',
  'Sans solde': 'unpaid',
  'Unpaid leave': 'unpaid',
  'بدون راتب': 'unpaid',
  'Congé familial': 'family',
  'Family leave': 'family',
  'إجازة عائلية': 'family',
};

export function leaveTypeCode(reason: string | null | undefined): string | null {
  if (!reason) return null;
  return LEAVE_TYPE_ALIASES[reason] ?? null;
}

export const LEAVE_TYPE_CODES = ['paid', 'rtt', 'unpaid', 'family'] as const;
