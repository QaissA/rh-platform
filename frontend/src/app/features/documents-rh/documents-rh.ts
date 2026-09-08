import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { UserAdminService } from '../../core/user-admin.service';
import { DocumentRequest, User } from '../../core/models';
import { fullName, jobTitleOf } from '../../core/format';
import { DOC_STATUS_CHIP, DOC_STATUS_LABEL, DOC_TYPE_LABEL } from '../../core/labels';

type Filter = 'open' | 'all';

@Component({
  selector: 'app-documents-rh',
  imports: [RouterLink],
  templateUrl: './documents-rh.html',
})
export class DocumentsRh {
  private docs = inject(DocumentService);
  private usersApi = inject(UserAdminService);

  protected loading = signal(true);
  protected filter = signal<Filter>('open');
  protected requests = signal<DocumentRequest[]>([]);
  private people = signal<Map<number, User>>(new Map());

  protected openCount = computed(
    () => this.requests().filter((r) => r.status === 'pending' || r.status === 'processing').length,
  );
  protected openRows = computed(() =>
    this.requests().filter((r) => r.status === 'pending' || r.status === 'processing'),
  );
  protected readyRows = computed(() => this.requests().filter((r) => r.status === 'ready'));

  protected typeLabel = (t: string) => DOC_TYPE_LABEL[t] ?? t;
  protected chip = (s: DocumentRequest['status']) => DOC_STATUS_CHIP[s] ?? 'mut';
  protected label = (s: DocumentRequest['status']) => DOC_STATUS_LABEL[s] ?? s;

  protected nameFor = (userId: number): string => {
    const u = this.people().get(userId);
    return u ? fullName(u) : `Utilisateur #${userId}`;
  };
  protected jobTitleFor = (userId: number): string | null => jobTitleOf(this.people().get(userId));

  constructor() {
    this.usersApi.list().subscribe((users) => {
      const map = new Map<number, User>();
      users.forEach((u) => map.set(u.id, u));
      this.people.set(map);
    });
    this.reload();
  }

  setFilter(f: Filter): void {
    if (this.filter() === f) return;
    this.filter.set(f);
    this.reload();
  }

  private reload(): void {
    this.loading.set(true);
    this.docs.getInbox().subscribe({
      next: (rs) => {
        const list = this.filter() === 'open'
          ? rs.filter((r) => r.status === 'pending' || r.status === 'processing')
          : rs;
        this.requests.set(list);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }
}
