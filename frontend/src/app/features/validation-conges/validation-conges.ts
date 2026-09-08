import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { LeaveService } from '../../core/leave.service';
import { TeamService } from '../../core/team.service';
import { UserAdminService } from '../../core/user-admin.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { LeaveRequest, LeaveStatus, TeamMember } from '../../core/models';
import { avatarClass, frRange, fullName, initials, jobTitleOf, workingDays } from '../../core/format';
import { LEAVE_STATUS_CHIP, LEAVE_STATUS_LABEL } from '../../core/labels';
import { StepTracker } from '../../shared/step-tracker';

type Filter = 'pending' | 'all';

@Component({
  selector: 'app-validation-conges',
  imports: [FormsModule, StepTracker],
  templateUrl: './validation-conges.html',
})
export class ValidationConges {
  private leave = inject(LeaveService);
  private team = inject(TeamService);
  private userAdmin = inject(UserAdminService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected filter = signal<Filter>('pending');
  protected requests = signal<LeaveRequest[]>([]);
  protected busyId = signal<number | null>(null);
  protected rejectingId = signal<number | null>(null);
  protected rejectComment = '';
  protected role = this.auth.user()?.role ?? '';

  // user_id -> { name, initials, avatar } for the people this approver can see.
  private people = signal<Map<number, TeamMember>>(new Map());

  protected pendingCount = computed(
    () => this.requests().filter((r) => this.isActionable(r)).length,
  );

  protected chip = (s: LeaveRequest['status']) => LEAVE_STATUS_CHIP[s] ?? 'mut';
  protected label = (s: LeaveRequest['status']) => LEAVE_STATUS_LABEL[s] ?? s;
  protected range = (r: LeaveRequest) => frRange(r.start_date, r.end_date);
  protected days = (r: LeaveRequest) => r.days ?? workingDays(r.start_date, r.end_date);
  protected intro = this.role === 'rh'
    ? 'Confirmez ou refusez les demandes déjà acceptées par le manager. Seule votre confirmation pose le congé.'
    : 'Approuvez ou refusez les demandes de votre équipe. Votre accord transmet la demande à la RH ; le solde n’est débité qu’après validation RH.';
  protected scopeLabel = this.role === 'manager' ? 'Équipe' : 'Entreprise';
  protected scopeSub = this.role === 'manager' ? 'Demandes que vous gérez' : 'Demandes à confirmer';
  protected queueTitle =
    this.role === 'rh' ? 'En attente RH' : this.role === 'admin' ? 'Files manager et RH' : 'En attente manager';

  protected nameFor = (userId: number): string => {
    const m = this.people().get(userId);
    return m ? fullName(m) : `Utilisateur #${userId}`;
  };
  protected jobTitleFor = (userId: number): string | null => jobTitleOf(this.people().get(userId));
  protected initialsFor = (userId: number): string => {
    const m = this.people().get(userId);
    return m ? initials(m) : '?';
  };
  protected avatarFor = (userId: number): string => avatarClass(userId);

  constructor() {
    this.loadPeople();
    this.reload();
  }

  isActionable(r: LeaveRequest): boolean {
    if (this.role === 'rh') return r.status === 'pending_hr';
    if (this.role === 'manager') return r.status === 'pending';
    return r.status === 'pending' || r.status === 'pending_hr';
  }

  setFilter(f: Filter): void {
    if (this.filter() === f) return;
    this.filter.set(f);
    this.rejectingId.set(null);
    this.reload();
  }

  approve(r: LeaveRequest): void {
    this.busyId.set(r.id);
    this.leave.approve(r.id).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.applyDecision(updated);
        this.toast.show(
          updated.status === 'pending_hr'
            ? `Demande transmise à la RH pour ${this.nameFor(r.user_id)}`
            : `Congé confirmé pour ${this.nameFor(r.user_id)}`,
        );
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'Approbation refusée'));
      },
    });
  }

  askReject(id: number): void {
    this.rejectComment = '';
    this.rejectingId.set(id);
  }
  cancelReject(): void {
    this.rejectingId.set(null);
  }
  confirmReject(r: LeaveRequest): void {
    this.busyId.set(r.id);
    this.leave.reject(r.id, this.rejectComment.trim() || undefined).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.rejectingId.set(null);
        this.applyDecision(updated);
        this.toast.show(`Congé refusé pour ${this.nameFor(r.user_id)}`);
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'Refus impossible'));
      },
    });
  }

  // Reflect a decided request: drop it in the pending view when it is no longer ours to act on.
  private applyDecision(updated: LeaveRequest): void {
    if (this.filter() === 'pending' && !this.isActionable(updated)) {
      this.requests.update((list) => list.filter((r) => r.id !== updated.id));
    } else {
      this.requests.update((list) => list.map((r) => (r.id === updated.id ? updated : r)));
    }
  }

  private reload(): void {
    this.loading.set(true);
    const status = this.filter() === 'pending' ? this.actionableStatuses() : undefined;
    this.leave.getTeamRequests(status).subscribe({
      next: (rs) => {
        this.requests.set(rs);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  private actionableStatuses(): LeaveStatus[] {
    if (this.role === 'rh') return ['pending_hr'];
    if (this.role === 'manager') return ['pending'];
    return ['pending', 'pending_hr'];
  }

  // Resolve names from whatever this role is allowed to read: admins and RH can
  // list every user; managers use their own team roster.
  private loadPeople(): void {
    const me = this.auth.user();
    const map = new Map<number, TeamMember>();
    const add = (m: TeamMember) => map.set(m.id, m);

    if (me?.role === 'admin' || me?.role === 'rh') {
      this.userAdmin.list().subscribe((users) => {
        users.forEach((u) =>
          add({
            id: u.id,
            email: u.email,
            first_name: u.first_name ?? null,
            last_name: u.last_name ?? null,
            role: u.role,
            job_title: u.job_title ?? null,
          }),
        );
        this.people.set(new Map(map));
      });
      return;
    }

    if (me) {
      add({
        id: me.id,
        email: me.email,
        first_name: me.first_name ?? null,
        last_name: me.last_name ?? null,
        role: me.role,
        job_title: me.job_title ?? null,
      });
    }
    this.team.getMine().subscribe((res) => {
      (res.members ?? []).forEach(add);
      this.people.set(new Map(map));
    });
  }

  private errorText(err: unknown, fallback: string): string {
    const e = err as { error?: { error?: string; errors?: string[] } };
    return e?.error?.error || e?.error?.errors?.join(', ') || fallback;
  }
}
