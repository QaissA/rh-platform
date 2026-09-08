import { Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { ToastService } from '../../core/toast.service';
import { DocumentRequest } from '../../core/models';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { DocumentPreview } from './document-preview';
import { downloadDocument } from '../../core/document-file';

@Component({
  selector: 'app-document-view',
  imports: [RouterLink, DocumentPreview, TranslatePipe],
  template: `
    <section class="view">
      @if (loading()) {
        <div class="loading"><span class="spinner"></span> {{ 'docs.loadingDoc' | t }}</div>
      } @else if (doc(); as r) {
        <div class="sectionhead no-print">
          <div>
            <a routerLink="/documents" class="rl" style="font-size:.82rem;color:var(--ink-3)">{{ 'docs.backMine' | t }}</a>
            <h3>{{ typeLabel(r.doc_type) }}</h3>
            <p>{{ 'docs.viewHelp' | t }}</p>
          </div>
          <div style="display:flex;gap:8px;flex-wrap:wrap">
            <button class="btn btn--ghost btn--sm" (click)="print()">{{ 'common.print' | t }}</button>
            <button class="btn btn--primary btn--sm" (click)="download(r)">{{ 'common.download' | t }}</button>
          </div>
        </div>
        <app-document-preview [doc]="r" />
      }
    </section>
  `,
})
export class DocumentView {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private docs = inject(DocumentService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected doc = signal<DocumentRequest | null>(null);
  protected typeLabel = (t: string) => this.i18n.t(`docType.${t}`);

  constructor() {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    const autoPrint = this.route.snapshot.queryParamMap.get('print') === '1';
    this.docs.getRequest(id).subscribe({
      next: (r) => {
        if (r.status !== 'ready') {
          this.toast.show(this.i18n.t('docs.notReady'));
          this.router.navigateByUrl('/documents');
          return;
        }
        this.doc.set(r);
        this.loading.set(false);
        if (autoPrint) setTimeout(() => window.print(), 250);
      },
      error: () => {
        this.loading.set(false);
        this.toast.show(this.i18n.t('docs.notFound'));
        this.router.navigateByUrl('/documents');
      },
    });
  }

  print(): void {
    window.print();
  }

  download(r: DocumentRequest): void {
    downloadDocument(r, this.i18n).catch(() => this.toast.show(this.i18n.t('docs.downloadFail')));
  }
}
