import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { UserAdminService } from '../../core/user-admin.service';
import { ToastService } from '../../core/toast.service';
import { DocumentRequest } from '../../core/models';
import { fullName } from '../../core/format';
import { DOC_STATUS_CHIP, DOC_STATUS_LABEL, DOC_TYPE_LABEL } from '../../core/labels';
import { TEMPLATE_FIELDS, TemplateField, defaultDocFields } from '../../core/document-templates';
import { DocumentPreview } from '../documents/document-preview';

@Component({
  selector: 'app-documents-rh-edit',
  imports: [FormsModule, RouterLink, DocumentPreview],
  templateUrl: './documents-rh-edit.html',
})
export class DocumentsRhEdit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private docs = inject(DocumentService);
  private usersApi = inject(UserAdminService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected saving = signal(false);
  protected request = signal<DocumentRequest | null>(null);
  protected fields: Record<string, string> = {};
  protected template: TemplateField[] = [];
  protected rejectComment = '';
  protected rejecting = signal(false);

  protected typeLabel = (t: string) => DOC_TYPE_LABEL[t] ?? t;
  protected chip = (s: string) => DOC_STATUS_CHIP[s as keyof typeof DOC_STATUS_CHIP] ?? 'mut';
  protected label = (s: string) => DOC_STATUS_LABEL[s as keyof typeof DOC_STATUS_LABEL] ?? s;

  constructor() {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.docs.getRequest(id).subscribe({
      next: (r) => this.hydrate(r),
      error: () => {
        this.loading.set(false);
        this.toast.show('Demande introuvable');
        this.router.navigateByUrl('/documents-rh');
      },
    });
  }

  protected previewDoc(): DocumentRequest {
    const r = this.request();
    return { ...(r as DocumentRequest), fields: this.fields };
  }

  save(status?: 'processing' | 'ready'): void {
    const r = this.request();
    if (!r || this.saving()) return;
    this.saving.set(true);
    this.docs.updateRequest(r.id, {
      fields: this.fields,
      ...(status ? { status } : r.status === 'pending' ? { status: 'processing' as const } : {}),
    }).subscribe({
      next: (updated) => {
        this.saving.set(false);
        this.hydrate(updated);
        this.toast.show(status === 'ready' ? 'Document mis à disposition du collaborateur' : 'Brouillon enregistré');
      },
      error: () => {
        this.saving.set(false);
        this.toast.show('Enregistrement impossible');
      },
    });
  }

  print(): void {
    window.print();
  }

  confirmReject(): void {
    const r = this.request();
    if (!r) return;
    this.saving.set(true);
    this.docs.updateRequest(r.id, { status: 'rejected', decision_comment: this.rejectComment.trim() || undefined }).subscribe({
      next: () => {
        this.saving.set(false);
        this.toast.show('Demande refusée');
        this.router.navigateByUrl('/documents-rh');
      },
      error: () => {
        this.saving.set(false);
        this.toast.show('Refus impossible');
      },
    });
  }

  private hydrate(r: DocumentRequest): void {
    this.usersApi.list().subscribe({
      next: (users) => {
        const u = users.find((x) => x.id === r.user_id);
        const name = u ? fullName(u) : `Utilisateur #${r.user_id}`;
        this.template = TEMPLATE_FIELDS[r.doc_type] ?? TEMPLATE_FIELDS['other'];
        this.fields = { ...defaultDocFields(r.doc_type, name, r.note), ...(r.fields ?? {}) };
        this.request.set({ ...r, fields: this.fields });
        this.loading.set(false);
      },
      error: () => {
        this.template = TEMPLATE_FIELDS[r.doc_type] ?? TEMPLATE_FIELDS['other'];
        this.fields = { ...defaultDocFields(r.doc_type, `Utilisateur #${r.user_id}`, r.note), ...(r.fields ?? {}) };
        this.request.set({ ...r, fields: this.fields });
        this.loading.set(false);
      },
    });
  }
}
