import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { UserAdminService } from '../../core/user-admin.service';
import { BusinessUnitAdminService } from '../../core/business-unit-admin.service';
import { TeamAdminService } from '../../core/team-admin.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { BusinessUnit, CreatedUser, TeamSummary, User } from '../../core/models';
import { avatarClass, fullName, initials } from '../../core/format';
import { ROLE_LABEL } from '../../core/labels';

const ROLE_CHIP: Record<string, string> = { admin: 'brand', rh: 'warn', manager: 'info', lead: 'info', employee: 'mut' };

// A pragmatic email check: non-empty local part, single @, and a domain with a
// dot-separated TLD (so "a.qaiss@netopia" without a TLD is rejected).
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

@Component({
  selector: 'app-users',
  imports: [FormsModule],
  templateUrl: './users.html',
})
export class Users {
  private api = inject(UserAdminService);
  private buApi = inject(BusinessUnitAdminService);
  private teamApi = inject(TeamAdminService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected users = signal<User[]>([]);
  protected busyId = signal<number | null>(null);
  protected confirmId = signal<number | null>(null);
  protected resetConfirmId = signal<number | null>(null);
  // Holds the account whose temporary password should be revealed to the admin.
  protected created = signal<CreatedUser | null>(null);
  // Distinguishes a freshly created account from a regenerated password.
  protected createdReset = signal(false);
  protected copied = signal(false);

  protected roles = ['employee', 'lead', 'manager', 'rh', 'admin'];

  // Org assignment: employees join a team (project + BU derived); managers get
  // a BU only. A single picker: "team:<id>" joins a team, "bu:<id>" is a BU-only
  // (manager) affectation, "" clears it.
  protected units = signal<BusinessUnit[]>([]);
  protected teams = signal<TeamSummary[]>([]);
  protected assigningId = signal<number | null>(null);
  protected assignValue = signal('');
  // Only teams that are linked to a project (and therefore a BU) are assignable.
  protected assignableTeams = computed(() => this.teams().filter((t) => !!t.business_unit));

  // create form
  protected email = '';
  protected firstName = '';
  protected lastName = '';
  protected role = 'employee';

  protected meId = computed(() => this.auth.user()?.id ?? -1);
  protected adminCount = computed(() => this.users().filter((u) => u.role === 'admin').length);

  protected emailValid = (): boolean => EMAIL_RE.test(this.email.trim());
  // Show the format error only once the user has typed something.
  protected emailInvalid = (): boolean => this.email.trim().length > 0 && !this.emailValid();

  protected name = (u: User) => fullName(u);
  protected initials = (u: User) => initials(u);
  protected av = (u: User) => avatarClass(u.id);
  protected roleLabel = (r: string) => ROLE_LABEL[r] ?? r;
  protected roleChip = (r: string) => ROLE_CHIP[r] ?? 'mut';

  protected buName = (id: number | null) => this.units().find((b) => b.id === id)?.name ?? null;
  protected teamName = (id: number | null) => this.teams().find((t) => t.id === id)?.name ?? null;
  // "Engineering · Atlas" (team member), "Engineering" (manager, BU only), or "—".
  protected assignmentLabel = (u: User): string => {
    const team = this.teamName(u.team_id);
    if (team) return `${this.buName(u.business_unit_id) ?? '—'} · ${team}`;
    const bu = this.buName(u.business_unit_id);
    return bu ?? '—';
  };

  constructor() {
    this.reload();
    this.loadOrg();
  }

  startAssign(user: User): void {
    // Preselect the user's current affectation: their team, else their BU.
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
    // "team:<id>" -> join a team (derives project+BU); "bu:<id>" -> BU only; "" -> clear.
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
        this.toast.show(`Affectation mise à jour pour ${this.name(user)}`);
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'Affectation refusée'));
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
          this.created.set(user); // reveal the one-time temporary password
          this.toast.show('Utilisateur créé');
          this.reload();
        },
        error: (err) => {
          this.submitting.set(false);
          this.toast.show(this.errorText(err, "Échec de la création"));
        },
      });
  }

  copyPassword(): void {
    const pwd = this.created()?.temporary_password;
    if (!pwd) return;
    navigator.clipboard?.writeText(pwd).then(
      () => {
        this.copied.set(true);
        this.toast.show('Mot de passe copié');
      },
      () => this.toast.show('Copie impossible'),
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
        this.toast.show(`${this.name(user)} est maintenant ${this.roleLabel(newRole).toLowerCase()}`);
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'Changement de rôle refusé'));
        this.reload(); // revert the select to the server value
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
        this.created.set(result); // reveal the new one-time temporary password
        this.toast.show(`Mot de passe réinitialisé pour ${this.name(user)}`);
        this.reload(); // pick up the refreshed must_change_password flag
      },
      error: (err) => {
        this.busyId.set(null);
        this.resetConfirmId.set(null);
        this.toast.show(this.errorText(err, 'Réinitialisation refusée'));
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
        this.toast.show(`${this.name(user)} supprimé·e`);
      },
      error: (err) => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.toast.show(this.errorText(err, 'Suppression refusée'));
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

  private errorText(err: unknown, fallback: string): string {
    const e = err as { error?: { error?: string; errors?: string[] } };
    return e?.error?.error || e?.error?.errors?.join(', ') || fallback;
  }
}
