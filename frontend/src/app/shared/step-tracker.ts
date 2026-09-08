import { Component, input } from '@angular/core';
import { LeaveStatus } from '../core/models';

@Component({
  selector: 'app-step-tracker',
  template: `
    <ol class="stepper" aria-label="Étapes de validation">
      <li [class.is-done]="managerDone()" [class.is-now]="status() === 'pending'">Manager</li>
      <li [class.is-done]="status() === 'approved'" [class.is-now]="status() === 'pending_hr'">RH</li>
    </ol>
  `,
})
export class StepTracker {
  readonly status = input.required<LeaveStatus>();

  protected managerDone(): boolean {
    const s = this.status();
    return s === 'pending_hr' || s === 'approved';
  }
}
