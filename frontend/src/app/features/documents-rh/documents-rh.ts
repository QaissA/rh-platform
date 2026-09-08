import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { PeopleService } from '../../core/people.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { InboxBadgeService } from '../../core/inbox-badge.service';
import { DocumentRequest } from '../../core/models';
import { DOC_STATUS_CHIP } from '../../core/labels';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';

type Filter = 'open' | 'all';

@Component({
  selector: 'app-documents-rh',
  imports: [FormsModule, RouterLink, TranslatePipe],
  templateUrl: './documents-rh.html',
})
export class DocumentsRh {
  private docs = inject(DocumentService);
  private people = inject(PeopleService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private badges = inject(InboxBadgeService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected filter = signal<Filter>('open');
  protected requests = signal<DocumentRequest[]>([]);
  protected busyId = signal<number | null>(null);
  protected rejectingId = signal<number | null>(null);
  protected rejectComment = '';

  protected openCount = computed(
    () => this.requests().filter((r) => this.isOpen(r)).length,
  );
  protected openRows = computed(() => this.requests().filter((r) => this.isOpen(r)));
  protected readyRows = computed(() => this.requests().filter((r) => r.status === 'ready'));
  protected closedRows = computed(() =>
    this.requests().filter((r) => r.status === 'rejected' || r.status === 'cancelled'),
  );

  protected typeLabel = (t: string) => this.i18n.t(`docType.${t}`);
  protected chip = (s: DocumentRequest['status']) => DOC_STATUS_CHIP[s] ?? 'mut';
  protected label = (s: DocumentRequest['status']) => this.i18n.t(`status.doc.${s}`);
  protected isOpen = (r: DocumentRequest) => r.status === 'pending' || r.status === 'processing';

  protected nameFor = (userId: number): string => this.people.nameOf(userId);
  protected jobTitleFor = (userId: number): string | null => this.people.jobTitleOf(userId);

  constructor() {
    this.people.load().subscribe();
    this.reload();
  }

  setFilter(f: Filter): void {
    if (this.filter() === f) return;
    this.filter.set(f);
    this.rejectingId.set(null);
    this.reload();
  }

  askReject(id: number): void {
    this.rejectComment = '';
    this.rejectingId.set(id);
  }

  cancelReject(): void {
    this.rejectingId.set(null);
  }

  confirmReject(r: DocumentRequest): void {
    this.busyId.set(r.id);
    this.docs.rejectRequest(r.id, this.rejectComment.trim() || undefined).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.rejectingId.set(null);
        if (this.filter() === 'open') {
          this.requests.update((list) => list.filter((row) => row.id !== updated.id));
        } else {
          this.requests.update((list) => list.map((row) => (row.id === updated.id ? updated : row)));
        }
        this.toast.show(this.i18n.t('docsRh.rejectedFor', { name: this.nameFor(r.user_id) }));
        this.badges.refresh(this.auth.user()?.role);
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show(this.i18n.t('docsRh.rejectFail'));
      },
    });
  }

  private reload(): void {
    this.loading.set(true);
    this.docs.getInbox().subscribe({
      next: (rs) => {
        const list = this.filter() === 'open'
          ? rs.filter((r) => this.isOpen(r))
          : rs;
        this.requests.set(list);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }
}
