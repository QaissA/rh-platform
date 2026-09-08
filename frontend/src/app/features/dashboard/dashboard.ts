import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { LeaveService } from '../../core/leave.service';
import { TeamService } from '../../core/team.service';
import { ScheduleService } from '../../core/schedule.service';
import { DocumentService } from '../../core/document.service';
import { UserAdminService } from '../../core/user-admin.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { InboxBadgeService } from '../../core/inbox-badge.service';
import {
  DocumentRequest,
  LeaveRequest,
  PresenceStatus,
  ScheduleEntry,
  TeamMember,
} from '../../core/models';
import {
  addDaysIso,
  avatarClass,
  frRange,
  fullName,
  initials,
  isoDate,
  jobTitleOf,
  startOfWeekIso,
  workingDays,
} from '../../core/format';
import {
  DOC_STATUS_CHIP,
  DOC_STATUS_LABEL,
  DOC_TYPE_LABEL,
  LEAVE_STATUS_CHIP,
  LEAVE_STATUS_LABEL,
  PRESENCE_CHIP,
  PRESENCE_LABEL,
} from '../../core/labels';
import { StepTracker } from '../../shared/step-tracker';

interface LeaveRow {
  id: number;
  range: string;
  type: string;
  days: number;
  status: LeaveRequest['status'];
  chip: string;
  label: string;
}

interface PresenceRow {
  id: number;
  initials: string;
  av: string;
  name: string;
  jobTitle: string | null;
  role: string;
  chip: string;
  label: string;
}

interface QueueRow {
  req: LeaveRequest;
  name: string;
  jobTitle: string | null;
  initials: string;
  av: string;
  range: string;
  days: number;
}

interface DocRow {
  id: number;
  title: string;
  status: DocumentRequest['status'];
  chip: string;
  label: string;
}

@Component({
  selector: 'app-dashboard',
  imports: [RouterLink, FormsModule, StepTracker],
  templateUrl: './dashboard.html',
})
export class Dashboard {
  private leave = inject(LeaveService);
  private team = inject(TeamService);
  private schedule = inject(ScheduleService);
  private docsApi = inject(DocumentService);
  private usersApi = inject(UserAdminService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private badges = inject(InboxBadgeService);

  protected loading = signal(true);
  protected balanceDays = signal(0);
  protected recent = signal<LeaveRow[]>([]);
  protected teamToday = signal<PresenceRow[]>([]);
  protected weekOut = signal<PresenceRow[]>([]);
  protected managerQueue = signal<QueueRow[]>([]);
  protected hrQueue = signal<QueueRow[]>([]);
  protected readyDocs = signal<DocRow[]>([]);
  protected waitingDocs = signal(0);
  protected openDocs = signal<DocRow[]>([]);
  protected nextLeave = signal<string | null>(null);
  protected teamName = signal<string | null>(null);

  protected busyId = signal<number | null>(null);
  protected rejectingId = signal<number | null>(null);
  protected rejectComment = '';

  private people = new Map<number, TeamMember>();

  protected firstName = computed(() => {
    const u = this.auth.user();
    return u ? fullName(u).split(' ')[0] : '';
  });
  protected role = computed(() => this.auth.user()?.role ?? '');
  protected isManager = computed(() => this.role() === 'manager' || this.role() === 'admin');
  protected isRh = computed(() => this.role() === 'rh' || this.role() === 'admin');

  constructor() {
    this.reload();
  }

  reload(): void {
    this.loading.set(true);
    const today = isoDate();
    const weekStart = startOfWeekIso();
    const weekEnd = addDaysIso(weekStart, 6);
    const role = this.auth.user()?.role;
    const emptyLeave: LeaveRequest[] = [];
    const emptyDocs: DocumentRequest[] = [];

    forkJoin({
      balance: this.leave.getBalance().pipe(catchError(() => of({ user_id: 0, days_remaining: 0 }))),
      requests: this.leave.getRequests().pipe(catchError(() => of(emptyLeave))),
      documents: this.docsApi.getRequests().pipe(catchError(() => of(emptyDocs))),
      team: this.team.getMine().pipe(catchError(() => of({ team: null, members: [] as TeamMember[] }))),
      today: this.schedule.getSchedule(today, today).pipe(catchError(() => of({ start: today, end: today, entries: [] as ScheduleEntry[] }))),
      week: this.schedule.getSchedule(weekStart, weekEnd).pipe(catchError(() => of({ start: weekStart, end: weekEnd, entries: [] as ScheduleEntry[] }))),
      pending: role === 'manager' || role === 'admin'
        ? this.leave.getTeamRequests('pending').pipe(catchError(() => of(emptyLeave)))
        : of(emptyLeave),
      pendingHr: role === 'rh' || role === 'admin'
        ? this.leave.getTeamRequests('pending_hr').pipe(catchError(() => of(emptyLeave)))
        : of(emptyLeave),
      inbox: role === 'rh' || role === 'admin'
        ? this.docsApi.getInbox().pipe(catchError(() => of(emptyDocs)))
        : of(emptyDocs),
    }).subscribe({
      next: (data) => {
        const me = this.auth.user();
        this.people.clear();
        if (me) {
          this.people.set(me.id, {
            id: me.id,
            email: me.email,
            first_name: me.first_name ?? null,
            last_name: me.last_name ?? null,
            role: me.role,
            job_title: me.job_title ?? null,
          });
        }
        (data.team.members ?? []).forEach((m) => this.people.set(m.id, m));
        this.teamName.set(data.team.team?.name ?? null);

        this.balanceDays.set(Number(data.balance.days_remaining) || 0);
        this.recent.set(data.requests.slice(0, 3).map((r) => this.toLeaveRow(r)));
        this.nextLeave.set(this.findNextLeave(data.requests, today));

        const ready = data.documents.filter((d) => d.status === 'ready');
        this.readyDocs.set(ready.slice(0, 4).map((d) => this.toDocRow(d)));
        this.waitingDocs.set(data.documents.filter((d) => d.status === 'pending' || d.status === 'processing').length);

        const roster = this.rosterFrom(me?.id, data.team.members ?? []);
        this.teamToday.set(this.presenceList(roster, data.today.entries, today));
        this.weekOut.set(this.outThisWeek(roster, data.week.entries, weekStart));

        this.managerQueue.set(data.pending.map((r) => this.toQueue(r)));
        this.hrQueue.set(data.pendingHr.map((r) => this.toQueue(r)));
        this.openDocs.set(
          data.inbox
            .filter((d) => d.status === 'pending' || d.status === 'processing')
            .slice(0, 3)
            .map((d) => this.toDocRow(d)),
        );

        this.loading.set(false);
        this.badges.refresh(role);

        if (role === 'rh' || role === 'admin') {
          this.usersApi.list().subscribe({
            next: (users) => {
              users.forEach((u) =>
                this.people.set(u.id, {
                  id: u.id,
                  email: u.email,
                  first_name: u.first_name ?? null,
                  last_name: u.last_name ?? null,
                  role: u.role,
                  job_title: u.job_title ?? null,
                }),
              );
              this.managerQueue.set(data.pending.map((r) => this.toQueue(r)));
              this.hrQueue.set(data.pendingHr.map((r) => this.toQueue(r)));
              this.openDocs.set(
                data.inbox
                  .filter((d) => d.status === 'pending' || d.status === 'processing')
                  .slice(0, 3)
                  .map((d) => this.toDocRow(d)),
              );
            },
          });
        }
      },
      error: () => {
        this.loading.set(false);
        this.toast.show('Impossible de charger le tableau de bord');
      },
    });
  }

  approve(r: LeaveRequest): void {
    this.busyId.set(r.id);
    this.leave.approve(r.id).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.toast.show(
          updated.status === 'pending_hr' ? 'Demande transmise à la RH' : 'Congé confirmé',
        );
        this.reload();
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show('Approbation impossible');
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
      next: () => {
        this.busyId.set(null);
        this.rejectingId.set(null);
        this.toast.show('Demande refusée');
        this.reload();
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show('Refus impossible');
      },
    });
  }

  private findNextLeave(requests: LeaveRequest[], today: string): string | null {
    const upcoming = requests
      .filter((r) => r.status === 'approved' && r.start_date >= today)
      .sort((a, b) => a.start_date.localeCompare(b.start_date));
    return upcoming[0] ? frRange(upcoming[0].start_date, upcoming[0].end_date) : null;
  }

  private toLeaveRow(r: LeaveRequest): LeaveRow {
    return {
      id: r.id,
      range: frRange(r.start_date, r.end_date),
      type: r.reason || 'Congés',
      days: workingDays(r.start_date, r.end_date),
      status: r.status,
      chip: LEAVE_STATUS_CHIP[r.status] ?? 'mut',
      label: LEAVE_STATUS_LABEL[r.status] ?? r.status,
    };
  }

  private toDocRow(d: DocumentRequest): DocRow {
    return {
      id: d.id,
      title: DOC_TYPE_LABEL[d.doc_type] ?? d.doc_type,
      status: d.status,
      chip: DOC_STATUS_CHIP[d.status] ?? 'mut',
      label: DOC_STATUS_LABEL[d.status] ?? d.status,
    };
  }

  private toQueue(r: LeaveRequest): QueueRow {
    const m = this.people.get(r.user_id);
    return {
      req: r,
      name: m ? fullName(m) : `Collaborateur #${r.user_id}`,
      jobTitle: jobTitleOf(m),
      initials: m ? initials(m) : '?',
      av: avatarClass(r.user_id),
      range: frRange(r.start_date, r.end_date),
      days: r.days ?? workingDays(r.start_date, r.end_date),
    };
  }

  private rosterFrom(meId: number | undefined, members: TeamMember[]): TeamMember[] {
    const list = [...members];
    const me = meId ? this.people.get(meId) : undefined;
    if (me && !list.some((m) => m.id === me.id)) list.unshift(me);
    return list;
  }

  private presenceList(roster: TeamMember[], entries: ScheduleEntry[], day: string): PresenceRow[] {
    return roster.map((m) => {
      const status: PresenceStatus =
        entries.find((e) => e.user_id === m.id && e.date === day)?.status ?? 'on_site';
      return this.toPresence(m, status);
    });
  }

  private outThisWeek(roster: TeamMember[], entries: ScheduleEntry[], weekStart: string): PresenceRow[] {
    const out: PresenceRow[] = [];
    for (const m of roster) {
      const onLeave = entries.some((e) => e.user_id === m.id && e.status === 'holiday' && e.date >= weekStart);
      if (onLeave) out.push(this.toPresence(m, 'holiday'));
    }
    return out;
  }

  private toPresence(m: TeamMember, status: PresenceStatus): PresenceRow {
    return {
      id: m.id,
      initials: initials(m),
      av: avatarClass(m.id),
      name: fullName(m),
      jobTitle: jobTitleOf(m),
      role: m.role,
      chip: PRESENCE_CHIP[status],
      label: PRESENCE_LABEL[status],
    };
  }
}
