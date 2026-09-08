import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { UserAdminService } from '../../core/user-admin.service';
import { BusinessUnitAdminService } from '../../core/business-unit-admin.service';
import { TeamAdminService } from '../../core/team-admin.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { BusinessUnit, CreatedUser, TeamSummary, User } from '../../core/models';
import { avatarClass, fullName, initials } from '../../core/format';
import { ROLE_CHIP } from '../../core/labels';

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

@Component({
  selector: 'app-users',
  imports: [FormsModule, TranslatePipe],
  templateUrl: './users.html',
})
export class Users {
  private api = inject(UserAdminService);
  private buApi = inject(BusinessUnitAdminService);
  private teamApi = inject(TeamAdminService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected users = signal<User[]>([]);
  protected busyId = signal<number | null>(null);
  protected confirmId = signal<number | null>(null);
  protected resetConfirmId = signal<number | null>(null);
  protected created = signal<CreatedUser | null>(null);
  protected createdReset = signal(false);
  protected copied = signal(false);

  protected roles = ['employee', 'lead', 'manager', 'rh', 'admin'];

  protected units = signal<BusinessUnit[]>([]);
  protected teams = signal<TeamSummary[]>([]);
  protected assigningId = signal<number | null>(null);
  protected assignValue = signal('');
  protected assignableTeams = computed(() => this.teams().filter((t) => !!t.business_unit));

  protected email = '';
  protected firstName = '';
  protected lastName = '';
  protected role = 'employee';

  protected meId = computed(() => this.auth.user()?.id ?? -1);
  protected adminCount = computed(() => this.users().filter((u) => u.role === 'admin').length);

  protected emailValid = (): boolean => EMAIL_RE.test(this.email.trim());
  protected emailInvalid = (): boolean => this.email.trim().length > 0 && !this.emailValid();

  protected name = (u: User) => fullName(u);
  protected initials = (u: User) => initials(u);
  protected av = (u: User) => avatarClass(u.id);
  protected roleLabel = (r: string) => this.i18n.t('status.role.' + r);
  protected roleChip = (r: string) => ROLE_CHIP[r] ?? 'mut';

  protected buName = (id: number | null) => this.units().find((b) => b.id === id)?.name ?? null;
  protected teamName = (id: number | null) => this.teams().find((t) => t.id === id)?.name ?? null;
  protected assignmentLabel = (u: User): string => {
    const dash = this.i18n.t('common.dash');
    const team = this.teamName(u.team_id);
    if (team) return `${this.buName(u.business_unit_id) ?? dash} · ${team}`;
    const bu = this.buName(u.business_unit_id);
    return bu ?? dash;
  };

  constructor() {
    this.reload();
    this.loadOrg();
  }

  startAssign(user: User): void {
    const current = user.team_id ? `team:${user.team_id}` : user.business_unit_id ? `bu:${user.business_unit_id}` : '';
    this.assignValue.set(current);
    this.assigningId.set(user.id);
  }
  cancelAssign(): void {
    this.assigningId.set(null);
  }
  saveAssign(user: User): void {
    this.busyId.set(user.id);
    const value = this.assignValue();
    let payload: { team_id?: number | null; business_unit_id?: number | null };
    if (value.startsWith('team:')) {
      payload = { team_id: Number(value.slice(5)) };
    } else if (value.startsWith('bu:')) {
      payload = { business_unit_id: Number(value.slice(3)), team_id: null };
    } else {
      payload = { business_unit_id: null, team_id: null };
    }
    this.api.update(user.id, payload).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.assigningId.set(null);
        this.users.update((list) => list.map((u) => (u.id === updated.id ? updated : u)));
        this.toast.show(this.i18n.t('users.assigned', { name: this.name(user) }));
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'users.assignFail'));
      },
    });
  }

  private loadOrg(): void {
    this.buApi.list().subscribe((b) => this.units.set(b));
    this.teamApi.list().subscribe((t) => this.teams.set(t));
  }

  togglePanel(): void {
    this.panelOpen.update((v) => !v);
  }

  submit(): void {
    if (this.submitting() || !this.emailValid()) return;
    this.submitting.set(true);
    this.api
      .create({
        email: this.email.trim(),
        first_name: this.firstName || undefined,
        last_name: this.lastName || undefined,
        role: this.role,
      })
      .subscribe({
        next: (user) => {
          this.submitting.set(false);
          this.panelOpen.set(false);
          this.resetForm();
          this.copied.set(false);
          this.createdReset.set(false);
          this.created.set(user);
          this.toast.show(this.i18n.t('users.created'));
          this.reload();
        },
        error: (err) => {
          this.submitting.set(false);
          this.toast.show(this.errorText(err, 'users.createFail'));
        },
      });
  }

  copyPassword(): void {
    const pwd = this.created()?.temporary_password;
    if (!pwd) return;
    navigator.clipboard?.writeText(pwd).then(
      () => {
        this.copied.set(true);
        this.toast.show(this.i18n.t('users.copied'));
      },
      () => this.toast.show(this.i18n.t('users.copyFail')),
    );
  }

  dismissCreated(): void {
    this.created.set(null);
  }

  changeRole(user: User, newRole: string): void {
    if (newRole === user.role) return;
    this.busyId.set(user.id);
    this.api.update(user.id, { role: newRole }).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.users.update((list) => list.map((u) => (u.id === updated.id ? updated : u)));
        this.toast.show(this.i18n.t('users.roleChanged', { name: this.name(user), role: this.roleLabel(newRole) }));
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'users.roleFail'));
        this.reload();
      },
    });
  }

  askReset(id: number): void {
    this.resetConfirmId.set(id);
  }
  cancelReset(): void {
    this.resetConfirmId.set(null);
  }
  confirmReset(user: User): void {
    this.busyId.set(user.id);
    this.api.resetPassword(user.id).subscribe({
      next: (result) => {
        this.busyId.set(null);
        this.resetConfirmId.set(null);
        this.copied.set(false);
        this.createdReset.set(true);
        this.created.set(result);
        this.toast.show(this.i18n.t('users.resetFor', { name: this.name(user) }));
        this.reload();
      },
      error: (err) => {
        this.busyId.set(null);
        this.resetConfirmId.set(null);
        this.toast.show(this.errorText(err, 'users.resetFail'));
      },
    });
  }

  askDelete(id: number): void {
    this.confirmId.set(id);
  }
  cancelDelete(): void {
    this.confirmId.set(null);
  }
  confirmDelete(user: User): void {
    this.busyId.set(user.id);
    this.api.remove(user.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.users.update((list) => list.filter((u) => u.id !== user.id));
        this.toast.show(this.i18n.t('users.deleted', { name: this.name(user) }));
      },
      error: (err) => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.toast.show(this.errorText(err, 'users.deleteFail'));
      },
    });
  }

  private reload(): void {
    this.loading.set(true);
    this.api.list().subscribe({
      next: (u) => {
        this.users.set(u);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  private resetForm(): void {
    this.email = '';
    this.firstName = '';
    this.lastName = '';
    this.role = 'employee';
  }

  private errorText(err: unknown, fallbackKey: string): string {
    const e = err as { error?: { error?: string; errors?: string[] } };
    return e?.error?.error || e?.error?.errors?.join(', ') || this.i18n.t(fallbackKey);
  }
}
