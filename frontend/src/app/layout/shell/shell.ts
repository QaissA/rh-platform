import { Component, HostListener, OnDestroy, computed, inject, signal } from '@angular/core';
import { NavigationEnd, Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { filter } from 'rxjs';
import { AuthService } from '../../core/auth.service';
import { ThemeService } from '../../core/theme.service';
import { NotificationService } from '../../core/notification.service';
import { InboxBadgeService } from '../../core/inbox-badge.service';
import { initials, fullName, jobTitleOf } from '../../core/format';
import { ROLE_LABEL } from '../../core/labels';
import { AppNotification } from '../../core/models';

const TITLES: Record<string, string> = {
  dashboard: 'Tableau de bord',
  conges: 'Congés',
  'validation-conges': 'Validation des congés',
  equipe: 'Mon équipe',
  equipes: 'Équipes',
  'business-units': 'Business Units',
  projets: 'Projets',
  documents: 'Documents',
  'documents-rh': 'Documents à traiter',
  dossiers: 'Dossiers',
  parametres: 'Paramètres',
  utilisateurs: 'Utilisateurs',
};

@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './shell.html',
})
export class Shell implements OnDestroy {
  private auth = inject(AuthService);
  private router = inject(Router);
  protected theme = inject(ThemeService);
  protected notifs = inject(NotificationService);
  protected badges = inject(InboxBadgeService);
  private poll: ReturnType<typeof setInterval> | null = null;

  protected user = this.auth.user;
  protected pageTitle = signal(this.titleFor(this.router.url));
  protected pageMeta = signal(this.metaFor(this.router.url));
  protected notifOpen = signal(false);

  protected displayName = computed(() => {
    const u = this.user();
    return u ? fullName(u) : 'Utilisateur';
  });
  protected jobTitle = computed(() => jobTitleOf(this.user()));
  protected userInitials = computed(() => {
    const u = this.user();
    return u ? initials(u) : '?';
  });
  protected roleLabel = computed(() => {
    const u = this.user();
    return u ? (ROLE_LABEL[u.role] ?? u.role) : '';
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
      .subscribe((e) => {
        this.pageTitle.set(this.titleFor(e.urlAfterRedirects));
        this.pageMeta.set(this.metaFor(e.urlAfterRedirects));
      });
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
    const d = new Date(iso);
    return new Intl.DateTimeFormat('fr-FR', {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    }).format(d);
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

  private titleFor(url: string): string {
    return TITLES[this.key(url)] ?? 'Alizé';
  }

  private metaFor(url: string): string {
    switch (this.key(url)) {
      case 'conges':
        return 'Solde et demandes';
      case 'validation-conges':
        return 'Demandes à valider';
      case 'equipe':
        return "Emploi du temps de l'équipe";
      case 'equipes':
        return 'Gestion des équipes';
      case 'business-units':
        return 'Unités & managers';
      case 'projets':
        return 'Projets & chef·fe·s de projet';
      case 'documents':
        return 'Démarches administratives';
      case 'documents-rh':
        return 'Rédaction et mise à disposition';
      case 'dossiers':
        return 'Fiches collaborateurs';
      case 'parametres':
        return 'Compte et coordonnées';
      default:
        return this.today();
    }
  }

  private today(): string {
    const s = new Intl.DateTimeFormat('fr-FR', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }).format(new Date());
    return s.charAt(0).toUpperCase() + s.slice(1);
  }
}
