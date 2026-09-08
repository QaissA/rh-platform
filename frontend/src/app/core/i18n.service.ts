import { Injectable, computed, signal } from '@angular/core';
import fr from '../../assets/i18n/fr.json';
import en from '../../assets/i18n/en.json';
import ar from '../../assets/i18n/ar.json';
import { formatDate, formatRange } from './format';

export type Lang = 'fr' | 'en' | 'ar';

const STORAGE_KEY = 'alize.lang';
const LOCALES: Record<Lang, string> = { fr: 'fr-FR', en: 'en-GB', ar: 'ar' };
const DICTS: Record<Lang, unknown> = { fr, en, ar };

function lookup(dict: unknown, path: string): string | undefined {
  let cur: unknown = dict;
  for (const part of path.split('.')) {
    if (!cur || typeof cur !== 'object' || !(part in cur)) return undefined;
    cur = (cur as Record<string, unknown>)[part];
  }
  return typeof cur === 'string' ? cur : undefined;
}

function interpolate(text: string, params?: Record<string, string | number>): string {
  if (!params) return text;
  return text.replace(/\{\{(\w+)\}\}/g, (_, key: string) =>
    params[key] === undefined || params[key] === null ? '' : String(params[key]),
  );
}

function readStored(): Lang {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw === 'fr' || raw === 'en' || raw === 'ar') return raw;
  } catch {
    /* private mode */
  }
  return 'fr';
}

@Injectable({ providedIn: 'root' })
export class I18nService {
  readonly lang = signal<Lang>(readStored());
  readonly dir = computed(() => (this.lang() === 'ar' ? 'rtl' : 'ltr'));
  readonly locale = computed(() => LOCALES[this.lang()]);

  constructor() {
    this.apply(this.lang());
  }

  t(key: string, params?: Record<string, string | number>): string {
    const raw =
      lookup(DICTS[this.lang()], key) ?? lookup(DICTS.fr, key) ?? key;
    return interpolate(raw, params);
  }

  setLang(lang: Lang): void {
    if (this.lang() === lang) return;
    this.lang.set(lang);
    try {
      localStorage.setItem(STORAGE_KEY, lang);
    } catch {
      /* private mode */
    }
    this.apply(lang);
  }

  formatDate(iso: string): string {
    return formatDate(iso, this.locale());
  }

  formatRange(startIso: string, endIso: string): string {
    return formatRange(startIso, endIso, this.locale());
  }

  private apply(lang: Lang): void {
    const html = document.documentElement;
    html.lang = lang;
    html.dir = lang === 'ar' ? 'rtl' : 'ltr';
  }
}
