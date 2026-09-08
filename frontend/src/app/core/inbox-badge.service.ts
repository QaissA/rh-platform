import { Injectable, inject, signal } from '@angular/core';
import { DocumentService } from './document.service';
import { LeaveService } from './leave.service';
import { LeaveStatus } from './models';

/** Sidebar queue counts for manager / RH. Best-effort; failures clear the badge. */
@Injectable({ providedIn: 'root' })
export class InboxBadgeService {
  private leave = inject(LeaveService);
  private docs = inject(DocumentService);

  readonly leaveQueue = signal(0);
  readonly docQueue = signal(0);

  refresh(role: string | undefined): void {
    if (role === 'manager' || role === 'rh' || role === 'admin') {
      const status: LeaveStatus | LeaveStatus[] =
        role === 'rh' ? 'pending_hr' : role === 'manager' ? 'pending' : ['pending', 'pending_hr'];
      this.leave.getTeamRequests(status).subscribe({
        next: (rs) => this.leaveQueue.set(rs.length),
        error: () => this.leaveQueue.set(0),
      });
    } else {
      this.leaveQueue.set(0);
    }

    if (role === 'rh' || role === 'admin') {
      this.docs.getInbox().subscribe({
        next: (rs) =>
          this.docQueue.set(rs.filter((r) => r.status === 'pending' || r.status === 'processing').length),
        error: () => this.docQueue.set(0),
      });
    } else {
      this.docQueue.set(0);
    }
  }

  clear(): void {
    this.leaveQueue.set(0);
    this.docQueue.set(0);
  }
}

