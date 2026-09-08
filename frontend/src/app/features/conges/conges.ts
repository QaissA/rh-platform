import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { LeaveService } from '../../core/leave.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { LeaveRequest, isAwaitingLeave } from '../../core/models';
import { workingDays } from '../../core/format';
import { LEAVE_STATUS_CHIP, LEAVE_TYPE_CODES, leaveTypeCode } from '../../core/labels';
import { StepTracker } from '../../shared/step-tracker';

@Component({
  selector: 'app-conges',
  imports: [FormsModule, StepTracker, TranslatePipe],
  templateUrl: './conges.html',
})
export class Conges {
  private leave = inject(LeaveService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected balanceDays = signal(0);
  protected requests = signal<LeaveRequest[]>([]);
  protected leaveTypes = LEAVE_TYPE_CODES;

  protected type = 'paid';
  protected startDate = signal('');
  protected endDate = signal('');
  protected reason = '';

  protected plannedDays = computed(() => {
    const s = this.startDate();
    const e = this.endDate();
    return s && e ? workingDays(s, e) : null;
  });

  protected approvedDays = computed(() =>
    this.sum(this.requests().filter((r) => r.status === 'approved')),
  );
  protected pendingReqs = computed(() => this.requests().filter((r) => isAwaitingLeave(r.status)));

  protected chip = (s: LeaveRequest['status']) => LEAVE_STATUS_CHIP[s] ?? 'mut';
  protected label = (s: LeaveRequest['status']) => this.i18n.t(`status.leave.${s}`);
  protected range = (r: LeaveRequest) => this.i18n.formatRange(r.start_date, r.end_date);
  protected days = (r: LeaveRequest) => workingDays(r.start_date, r.end_date);
  protected reasonLabel = (reason: string | null) => {
    const code = leaveTypeCode(reason);
    return code ? this.i18n.t(`leave.types.${code}`) : (reason || this.i18n.t('leave.defaultReason'));
  };

  constructor() {
    this.reload();
  }

  togglePanel(): void {
    this.panelOpen.update((v) => !v);
  }

  submit(): void {
    if (this.submitting() || !this.startDate() || !this.endDate()) return;
    this.submitting.set(true);
    const reason = this.reason.trim() || this.type;
    this.leave
      .createRequest({ start_date: this.startDate(), end_date: this.endDate(), reason })
      .subscribe({
        next: () => {
          this.submitting.set(false);
          this.panelOpen.set(false);
          this.reason = '';
          this.toast.show(this.i18n.t('leave.sent'));
          this.reload();
        },
        error: () => {
          this.submitting.set(false);
          this.toast.show(this.i18n.t('leave.sendFail'));
        },
      });
  }

  private reload(): void {
    this.loading.set(true);
    this.leave.getBalance().subscribe((b) => this.balanceDays.set(Number(b.days_remaining) || 0));
    this.leave.getRequests().subscribe({
      next: (rs) => {
        this.requests.set(rs);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  private sum(rs: LeaveRequest[]): number {
    return rs.reduce((acc, r) => acc + workingDays(r.start_date, r.end_date), 0);
  }
}
