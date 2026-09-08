import { Component, input } from '@angular/core';
import { DocumentRequest } from '../../core/models';
import { DOC_TYPE_LABEL } from '../../core/labels';
import { frDate } from '../../core/format';

@Component({
  selector: 'app-document-preview',
  templateUrl: './document-preview.html',
})
export class DocumentPreview {
  readonly doc = input.required<DocumentRequest>();

  protected f(key: string): string {
    return this.doc().fields?.[key] ?? '';
  }

  protected typeLabel(): string {
    return this.f('title') || DOC_TYPE_LABEL[this.doc().doc_type] || 'Document';
  }

  protected issued(): string {
    const raw = this.f('issued_date');
    return raw ? frDate(raw) : '';
  }

  protected pretty(key: string): string {
    const raw = this.f(key);
    if (!raw) return '………………';
    return key.endsWith('_date') || key === 'leave_start' || key === 'leave_end' ? frDate(raw) : raw;
  }
}
