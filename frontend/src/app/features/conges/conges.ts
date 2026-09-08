import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { LeaveService } from '../../core/leave.service';
import { ToastService } from '../../core/toast.service';
import { LeaveRequest, isAwaitingLeave } from '../../core/models';
import { frRange, workingDays } from '../../core/format';
import { LEAVE_STATUS_CHIP, LEAVE_STATUS_LABEL } from '../../core/labels';
import { StepTracker } from '../../shared/step-tracker';

@Component({
  selector: 'app-conges',
  imports: [FormsModule, StepTracker],
  templateUrl: './conges.html',
})
export class Conges {
  private leave = inject(LeaveService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected balanceDays = signal(0);
  protected requests = signal<LeaveRequest[]>([]);

  // form model (signals so the planned-days count stays reactive)
  protected type = 'Congés payés';
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
  protected label = (s: LeaveRequest['status']) => LEAVE_STATUS_LABEL[s] ?? s;
  protected range = (r: LeaveRequest) => frRange(r.start_date, r.end_date);
  protected days = (r: LeaveRequest) => workingDays(r.start_date, r.end_date);

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
          this.toast.show('Demande de congé envoyée');
          this.reload();
        },
        error: () => {
          this.submitting.set(false);
          this.toast.show("Échec de l'envoi de la demande");
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
