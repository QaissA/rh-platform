import { Component, input } from '@angular/core';
import { LeaveStatus } from '../core/models';
import { TranslatePipe } from '../core/translate.pipe';

@Component({
  selector: 'app-step-tracker',
  imports: [TranslatePipe],
  template: `
    <ol class="stepper" [attr.aria-label]="'stepper.label' | t">
      <li [class.is-done]="managerDone()" [class.is-now]="status() === 'pending'">{{ 'stepper.manager' | t }}</li>
      <li [class.is-done]="status() === 'approved'" [class.is-now]="status() === 'pending_hr'">{{ 'stepper.hr' | t }}</li>
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
