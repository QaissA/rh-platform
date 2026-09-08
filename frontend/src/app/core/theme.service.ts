import { Injectable, signal } from '@angular/core';

type Theme = 'light' | 'dark';
const THEME_KEY = 'alize.theme';

@Injectable({ providedIn: 'root' })
export class ThemeService {
  /** null = follow the OS preference. */
  private _override = signal<Theme | null>(read());

  readonly isDark = signal<boolean>(this.resolveDark());

  constructor() {
    const saved = this._override();
    if (saved) {
      document.documentElement.setAttribute('data-theme', saved);
    }
    window
      .matchMedia('(prefers-color-scheme: dark)')
      .addEventListener('change', () => {
        if (!this._override()) this.isDark.set(this.resolveDark());
      });
  }

  toggle(): void {
    const next: Theme = this.isDark() ? 'light' : 'dark';
    this._override.set(next);
    localStorage.setItem(THEME_KEY, next);
    document.documentElement.setAttribute('data-theme', next);
    this.isDark.set(next === 'dark');
  }

  private resolveDark(): boolean {
    const o = this._override();
    if (o) return o === 'dark';
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
}

function read(): Theme | null {
  const v = localStorage.getItem(THEME_KEY);
  return v === 'light' || v === 'dark' ? v : null;
}
