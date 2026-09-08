import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { ToastService } from '../../core/toast.service';
import { DocumentRequest } from '../../core/models';
import { DOC_STATUS_CHIP } from '../../core/labels';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { downloadDocument } from '../../core/document-file';

const DOC_TYPES = ['work_certificate', 'salary_certificate', 'leave_attestation', 'other'];

@Component({
  selector: 'app-documents',
  imports: [FormsModule, TranslatePipe],
  templateUrl: './documents.html',
})
export class Documents {
  private docs = inject(DocumentService);
  private toast = inject(ToastService);
  private router = inject(Router);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected requests = signal<DocumentRequest[]>([]);
  protected busyId = signal<number | null>(null);
  protected waiting = computed(() => this.requests().filter((r) => r.status === 'pending' || r.status === 'processing'));
  protected ready = computed(() => this.requests().filter((r) => r.status === 'ready'));
  protected closed = computed(() => this.requests().filter((r) => r.status === 'rejected' || r.status === 'cancelled'));

  protected docTypes = DOC_TYPES;
  protected docType = DOC_TYPES[0];
  protected note = '';

  protected typeLabel = (t: string) => this.i18n.t(`docType.${t}`);
  protected chip = (s: DocumentRequest['status']) => DOC_STATUS_CHIP[s] ?? 'mut';
  protected label = (s: DocumentRequest['status']) => this.i18n.t(`status.doc.${s}`);

  constructor() {
    this.reload();
  }

  togglePanel(): void {
    this.panelOpen.update((v) => !v);
  }

  submit(): void {
    if (this.submitting()) return;
    this.submitting.set(true);
    this.docs.createRequest({ doc_type: this.docType, note: this.note.trim() || undefined }).subscribe({
      next: () => {
        this.submitting.set(false);
        this.panelOpen.set(false);
        this.note = '';
        this.toast.show(this.i18n.t('docs.created'));
        this.reload();
      },
      error: () => {
        this.submitting.set(false);
        this.toast.show(this.i18n.t('docs.createFail'));
      },
    });
  }

  cancel(r: DocumentRequest): void {
    if (this.busyId() === r.id) return;
    this.busyId.set(r.id);
    this.docs.cancelRequest(r.id).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.requests.update((list) => list.map((row) => (row.id === updated.id ? updated : row)));
        this.toast.show(this.i18n.t('docs.cancelled'));
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show(this.i18n.t('docs.cancelFail'));
      },
    });
  }

  print(r: DocumentRequest): void {
    this.router.navigate(['/documents', r.id], { queryParams: { print: '1' } });
  }

  download(r: DocumentRequest): void {
    this.docs.getRequest(r.id).subscribe({
      next: (full) => {
        downloadDocument(full, this.i18n).catch(() => this.toast.show(this.i18n.t('docs.downloadFail')));
      },
      error: () => this.toast.show(this.i18n.t('docs.downloadFail')),
    });
  }

  private reload(): void {
    this.loading.set(true);
    this.docs.getRequests().subscribe({
      next: (rs) => {
        this.requests.set(rs);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }
}
