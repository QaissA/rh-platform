import { Component, HostListener, OnDestroy, computed, inject, signal } from '@angular/core';
import { NavigationEnd, Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { filter } from 'rxjs';
import { AuthService } from '../../core/auth.service';
import { ThemeService } from '../../core/theme.service';
import { NotificationService } from '../../core/notification.service';
import { InboxBadgeService } from '../../core/inbox-badge.service';
import { ChatService } from '../../core/chat.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { LangSwitcher } from '../../shared/lang-switcher';
import { initials, fullName, jobTitleOf } from '../../core/format';
import { AppNotification } from '../../core/models';

@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, TranslatePipe, LangSwitcher],
  templateUrl: './shell.html',
})
export class Shell implements OnDestroy {
  private auth = inject(AuthService);
  private router = inject(Router);
  protected theme = inject(ThemeService);
  protected notifs = inject(NotificationService);
  protected badges = inject(InboxBadgeService);
  protected chat = inject(ChatService);
  protected i18n = inject(I18nService);
  private poll: ReturnType<typeof setInterval> | null = null;

  protected user = this.auth.user;
  protected pageKey = signal(this.key(this.router.url));
  protected notifOpen = signal(false);

  protected pageTitle = computed(() => {
    this.i18n.lang();
    const k = this.pageKey();
    const title = this.i18n.t(`page.${k}.title`);
    return title === `page.${k}.title` ? this.i18n.t('brand') : title;
  });
  protected pageMeta = computed(() => {
    this.i18n.lang();
    const k = this.pageKey();
    if (k === 'dashboard') return this.today();
    const meta = this.i18n.t(`page.${k}.meta`);
    return meta === `page.${k}.meta` ? this.today() : meta;
  });

  protected displayName = computed(() => {
    const u = this.user();
    return u ? fullName(u) : this.i18n.t('common.user');
  });
  protected jobTitle = computed(() => jobTitleOf(this.user()));
  protected userInitials = computed(() => {
    const u = this.user();
    return u ? initials(u) : '?';
  });
  protected roleLabel = computed(() => {
    this.i18n.lang();
    const u = this.user();
    return u ? this.i18n.t(`status.role.${u.role}`) : '';
  });
  protected isAdmin = computed(() => this.user()?.role === 'admin');
  protected isRh = computed(() => {
    const role = this.user()?.role;
    return role === 'rh' || role === 'admin';
  });
  protected isManager = computed(() => {
    const role = this.user()?.role;
    return role === 'manager' || role === 'rh' || role === 'admin';
  });

  constructor() {
    this.notifs.load();
    this.badges.refresh(this.user()?.role);
    this.poll = setInterval(() => {
      this.notifs.load();
      this.badges.refresh(this.user()?.role);
    }, 20000);
    this.router.events
      .pipe(filter((e): e is NavigationEnd => e instanceof NavigationEnd))
      .subscribe((e) => this.pageKey.set(this.key(e.urlAfterRedirects)));
  }

  @HostListener('document:click')
  closeNotifs(): void {
    this.notifOpen.set(false);
  }

  toggleNotifs(event: Event): void {
    event.stopPropagation();
    this.notifOpen.update((v) => !v);
    if (this.notifOpen()) this.notifs.load();
  }

  openNotif(n: AppNotification, event: Event): void {
    event.stopPropagation();
    if (!n.read) this.notifs.markRead(n.id);
    this.notifOpen.set(false);
    if (n.link) this.router.navigateByUrl(n.link);
  }

  when(iso: string): string {
    return new Intl.DateTimeFormat(this.i18n.locale(), {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    }).format(new Date(iso));
  }

  ngOnDestroy(): void {
    if (this.poll) clearInterval(this.poll);
  }

  logout(): void {
    this.auth.logout();
    this.router.navigateByUrl('/login');
  }

  private key(url: string): string {
    return url.split('?')[0].split('/').filter(Boolean)[0] ?? 'dashboard';
  }

  private today(): string {
    const s = new Intl.DateTimeFormat(this.i18n.locale(), {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }).format(new Date());
    return s.charAt(0).toUpperCase() + s.slice(1);
  }
}
