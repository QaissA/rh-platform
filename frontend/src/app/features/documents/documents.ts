import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { ToastService } from '../../core/toast.service';
import { DocumentRequest } from '../../core/models';
import { DOC_STATUS_CHIP, DOC_STATUS_LABEL, DOC_TYPE_LABEL } from '../../core/labels';
import { downloadDocument } from '../../core/document-file';

const DOC_TYPES = [
  { value: 'work_certificate', label: 'Attestation de travail' },
  { value: 'salary_certificate', label: 'Bulletin de paie' },
  { value: 'leave_attestation', label: 'Attestation de congés' },
  { value: 'other', label: 'Autre' },
];

@Component({
  selector: 'app-documents',
  imports: [FormsModule],
  templateUrl: './documents.html',
})
export class Documents {
  private docs = inject(DocumentService);
  private toast = inject(ToastService);
  private router = inject(Router);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected requests = signal<DocumentRequest[]>([]);
  protected waiting = computed(() => this.requests().filter((r) => r.status === 'pending' || r.status === 'processing'));
  protected ready = computed(() => this.requests().filter((r) => r.status === 'ready'));

  protected docTypes = DOC_TYPES;
  protected docType = DOC_TYPES[0].value;
  protected note = '';

  protected typeLabel = (t: string) => DOC_TYPE_LABEL[t] ?? t;
  protected chip = (s: DocumentRequest['status']) => DOC_STATUS_CHIP[s] ?? 'mut';
  protected label = (s: DocumentRequest['status']) => DOC_STATUS_LABEL[s] ?? s;

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
        this.toast.show('Demande de document enregistrée');
        this.reload();
      },
      error: () => {
        this.submitting.set(false);
        this.toast.show("Échec de l'envoi de la demande");
      },
    });
  }

  print(r: DocumentRequest): void {
    this.router.navigate(['/documents', r.id], { queryParams: { print: '1' } });
  }

  download(r: DocumentRequest): void {
    this.docs.getRequest(r.id).subscribe({
      next: (full) => {
        downloadDocument(full).catch(() => this.toast.show('Téléchargement impossible'));
      },
      error: () => this.toast.show('Téléchargement impossible'),
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
