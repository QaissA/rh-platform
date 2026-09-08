import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { API_BASE_URL } from './api';
import { AppNotification } from './models';

@Injectable({ providedIn: 'root' })
export class NotificationService {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  readonly items = signal<AppNotification[]>([]);
  readonly unreadCount = computed(() => this.items().filter((n) => !n.read).length);

  clear(): void {
    this.items.set([]);
  }

  load(): void {
    this.http.get<AppNotification[]>(`${this.base}/auth/notifications`).subscribe({
      next: (list) => this.items.set(list),
      error: () => undefined,
    });
  }

  markRead(id: number): void {
    this.http.patch<AppNotification>(`${this.base}/auth/notifications/${id}/read`, {}).subscribe({
      next: (updated) => {
        this.items.update((list) => list.map((n) => (n.id === updated.id ? updated : n)));
      },
    });
  }
}
