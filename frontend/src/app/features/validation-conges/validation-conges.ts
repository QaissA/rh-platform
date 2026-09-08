import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { LeaveService } from '../../core/leave.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { PeopleService } from '../../core/people.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { LeaveRequest, LeaveStatus } from '../../core/models';
import { avatarClass, workingDays } from '../../core/format';
import { LEAVE_STATUS_CHIP } from '../../core/labels';
import { StepTracker } from '../../shared/step-tracker';

type Filter = 'pending' | 'all';

@Component({
  selector: 'app-validation-conges',
  imports: [FormsModule, StepTracker, TranslatePipe],
  templateUrl: './validation-conges.html',
})
export class ValidationConges {
  private leave = inject(LeaveService);
  private people = inject(PeopleService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected filter = signal<Filter>('pending');
  protected requests = signal<LeaveRequest[]>([]);
  protected busyId = signal<number | null>(null);
  protected rejectingId = signal<number | null>(null);
  protected rejectComment = '';
  protected role = this.auth.user()?.role ?? '';

  protected pendingCount = computed(
    () => this.requests().filter((r) => this.isActionable(r)).length,
  );

  protected chip = (s: LeaveRequest['status']) => LEAVE_STATUS_CHIP[s] ?? 'mut';
  protected label = (s: LeaveRequest['status']) => this.i18n.t(`status.leave.${s}`);
  protected range = (r: LeaveRequest) => this.i18n.formatRange(r.start_date, r.end_date);
  protected days = (r: LeaveRequest) => r.days ?? workingDays(r.start_date, r.end_date);
  protected intro = (): string =>
    this.i18n.t(this.role === 'rh' ? 'leaveReview.introRh' : 'leaveReview.introManager');
  protected scopeLabel = (): string =>
    this.i18n.t(this.role === 'manager' ? 'leaveReview.scopeTeam' : 'leaveReview.scopeCompany');
  protected scopeSub = (): string =>
    this.i18n.t(this.role === 'manager' ? 'leaveReview.scopeTeamSub' : 'leaveReview.scopeCompanySub');
  protected queueTitle = (): string => {
    if (this.role === 'rh') return this.i18n.t('leaveReview.queueRh');
    if (this.role === 'admin') return this.i18n.t('leaveReview.queueAdmin');
    return this.i18n.t('leaveReview.queueManager');
  };

  protected nameFor = (userId: number): string => this.people.nameOf(userId);
  protected jobTitleFor = (userId: number): string | null => this.people.jobTitleOf(userId);
  protected initialsFor = (userId: number): string => this.people.initialsOf(userId);
  protected avatarFor = (userId: number): string => avatarClass(userId);

  constructor() {
    this.people.load().subscribe();
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
        const name = this.nameFor(r.user_id);
        this.toast.show(
          updated.status === 'pending_hr'
            ? this.i18n.t('leaveReview.forwarded', { name })
            : this.i18n.t('leaveReview.confirmed', { name }),
        );
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, this.i18n.t('leaveReview.approveFail')));
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
        this.toast.show(this.i18n.t('leaveReview.rejectedFor', { name: this.nameFor(r.user_id) }));
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, this.i18n.t('leaveReview.rejectFail')));
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

  private errorText(err: unknown, fallback: string): string {
    const e = err as { error?: { error?: string; errors?: string[] } };
    return e?.error?.error || e?.error?.errors?.join(', ') || fallback;
  }
}
