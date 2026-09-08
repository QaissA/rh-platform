interface NameLike {
  first_name?: string | null;
  last_name?: string | null;
  email: string;
  job_title?: string | null;
}

const AVATAR_CLASSES = ['av1', 'av2', 'av3', 'av4', 'av5', 'av6', 'av7'];

/** Full name from a member, falling back to the email local-part. */
export function fullName(m: NameLike): string {
  const name = [m.first_name, m.last_name].filter(Boolean).join(' ').trim();
  return name || m.email.split('@')[0];
}

/** Confirmed job title, or null when none is set. */
export function jobTitleOf(m: { job_title?: string | null } | null | undefined): string | null {
  const title = m?.job_title?.trim();
  return title || null;
}

/** Two-letter initials for avatars. */
export function initials(m: NameLike): string {
  if (m.first_name || m.last_name) {
    return `${(m.first_name ?? '')[0] ?? ''}${(m.last_name ?? '')[0] ?? ''}`.toUpperCase() || '?';
  }
  return m.email.slice(0, 2).toUpperCase();
}

/** Deterministic avatar color class from an id. */
export function avatarClass(id: number): string {
  return AVATAR_CLASSES[id % AVATAR_CLASSES.length];
}

/** Locale-aware calendar date: "1 Aug 2026" / "01 août 2026". */
export function formatDate(iso: string, locale = 'fr-FR'): string {
  const d = new Date(iso.includes('T') ? iso : `${iso}T12:00:00`);
  if (isNaN(d.getTime())) return iso;
  return new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'short', year: 'numeric' }).format(d);
}

/** Compact range for the active locale. */
export function formatRange(startIso: string, endIso: string, locale = 'fr-FR'): string {
  const s = new Date(startIso.includes('T') ? startIso : `${startIso}T12:00:00`);
  const e = new Date(endIso.includes('T') ? endIso : `${endIso}T12:00:00`);
  if (isNaN(s.getTime()) || isNaN(e.getTime())) return `${startIso} – ${endIso}`;
  if (s.getTime() === e.getTime()) return formatDate(startIso, locale);
  const sameMonth = s.getMonth() === e.getMonth() && s.getFullYear() === e.getFullYear();
  if (sameMonth) {
    const day = new Intl.DateTimeFormat(locale, { day: 'numeric' });
    const rest = new Intl.DateTimeFormat(locale, { month: 'short', year: 'numeric' });
    return `${day.format(s)}–${day.format(e)} ${rest.format(s)}`;
  }
  return `${formatDate(startIso, locale)} – ${formatDate(endIso, locale)}`;
}

/** @deprecated use formatDate */
export function frDate(iso: string): string {
  return formatDate(iso, 'fr-FR');
}

/** @deprecated use formatRange */
export function frRange(startIso: string, endIso: string): string {
  return formatRange(startIso, endIso, 'fr-FR');
}

/** Local calendar day as YYYY-MM-DD. */
export function isoDate(d = new Date()): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

/** Monday of the week containing `d` (ISO week, Monday start). */
export function startOfWeekIso(d = new Date()): string {
  const x = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const day = x.getDay();
  x.setDate(x.getDate() + (day === 0 ? -6 : 1 - day));
  return isoDate(x);
}

export function addDaysIso(iso: string, days: number): string {
  const x = new Date(`${iso}T12:00:00`);
  x.setDate(x.getDate() + days);
  return isoDate(x);
}

/** Inclusive business-day-ish span in whole days (weekends excluded). */
export function workingDays(startIso: string, endIso: string): number {
  const s = new Date(startIso);
  const e = new Date(endIso);
  if (isNaN(s.getTime()) || isNaN(e.getTime()) || e < s) return 0;
  let count = 0;
  const cur = new Date(s);
  while (cur <= e) {
    const day = cur.getDay();
    if (day !== 0 && day !== 6) count++;
    cur.setDate(cur.getDate() + 1);
  }
  return count;
}
