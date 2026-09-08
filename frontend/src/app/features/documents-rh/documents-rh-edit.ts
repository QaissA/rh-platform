import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { UserAdminService } from '../../core/user-admin.service';
import { ToastService } from '../../core/toast.service';
import { DocumentRequest } from '../../core/models';
import { fullName } from '../../core/format';
import { DOC_STATUS_CHIP } from '../../core/labels';
import { TEMPLATE_FIELDS, TemplateField, defaultDocFields } from '../../core/document-templates';
import { DocumentPreview } from '../documents/document-preview';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';

@Component({
  selector: 'app-documents-rh-edit',
  imports: [FormsModule, RouterLink, DocumentPreview, TranslatePipe],
  templateUrl: './documents-rh-edit.html',
})
export class DocumentsRhEdit {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private docs = inject(DocumentService);
  private usersApi = inject(UserAdminService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected saving = signal(false);
  protected request = signal<DocumentRequest | null>(null);
  protected fields: Record<string, string> = {};
  protected template: TemplateField[] = [];
  protected rejectComment = '';
  protected rejecting = signal(false);

  protected typeLabel = (t: string) => this.i18n.t(`docType.${t}`);
  protected chip = (s: string) => DOC_STATUS_CHIP[s as keyof typeof DOC_STATUS_CHIP] ?? 'mut';
  protected label = (s: string) => this.i18n.t(`status.doc.${s}`);

  constructor() {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.docs.getRequest(id).subscribe({
      next: (r) => this.hydrate(r),
      error: () => {
        this.loading.set(false);
        this.toast.show(this.i18n.t('docsRh.notFound'));
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
        this.toast.show(this.i18n.t(status === 'ready' ? 'docsRh.savedReady' : 'docsRh.savedDraft'));
      },
      error: () => {
        this.saving.set(false);
        this.toast.show(this.i18n.t('docsRh.saveFail'));
      },
    });
  }

  print(): void {
    window.print();
  }

  confirmReject(): void {
    const r = this.request();
    if (!r || this.saving()) return;
    this.saving.set(true);
    this.docs.rejectRequest(r.id, this.rejectComment.trim() || undefined).subscribe({
      next: () => {
        this.saving.set(false);
        this.toast.show(this.i18n.t('docsRh.rejectedToast'));
        this.router.navigateByUrl('/documents-rh');
      },
      error: () => {
        this.saving.set(false);
        this.toast.show(this.i18n.t('docsRh.rejectFail'));
      },
    });
  }

  private hydrate(r: DocumentRequest): void {
    this.usersApi.list().subscribe({
      next: (users) => {
        const u = users.find((x) => x.id === r.user_id);
        const name = u ? fullName(u) : this.i18n.t('common.userN', { id: r.user_id });
        this.template = TEMPLATE_FIELDS[r.doc_type] ?? TEMPLATE_FIELDS['other'];
        this.fields = { ...defaultDocFields(r.doc_type, name, r.note, (k, p) => this.i18n.t(k, p)), ...(r.fields ?? {}) };
        this.request.set({ ...r, fields: this.fields });
        this.loading.set(false);
      },
      error: () => {
        this.template = TEMPLATE_FIELDS[r.doc_type] ?? TEMPLATE_FIELDS['other'];
        this.fields = { ...defaultDocFields(r.doc_type, this.i18n.t('common.userN', { id: r.user_id }), r.note, (k, p) => this.i18n.t(k, p)), ...(r.fields ?? {}) };
        this.request.set({ ...r, fields: this.fields });
        this.loading.set(false);
      },
    });
  }
}
