import { Component, inject, input } from '@angular/core';
import { DocumentRequest } from '../../core/models';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';

@Component({
  selector: 'app-document-preview',
  imports: [TranslatePipe],
  templateUrl: './document-preview.html',
})
export class DocumentPreview {
  private i18n = inject(I18nService);
  readonly doc = input.required<DocumentRequest>();

  protected f(key: string): string {
    return this.doc().fields?.[key] ?? '';
  }

  protected typeLabel(): string {
    return this.f('title') || this.i18n.t(`docType.${this.doc().doc_type}`);
  }

  protected issued(): string {
    const raw = this.f('issued_date');
    return raw ? this.i18n.formatDate(raw) : '';
  }

  protected pretty(key: string): string {
    const raw = this.f(key);
    if (!raw) return this.i18n.t('docSheet.blank');
    return key.endsWith('_date') || key === 'leave_start' || key === 'leave_end'
      ? this.i18n.formatDate(raw)
      : raw;
  }
}
