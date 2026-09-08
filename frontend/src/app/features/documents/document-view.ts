import { Component, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { DocumentService } from '../../core/document.service';
import { ToastService } from '../../core/toast.service';
import { DocumentRequest } from '../../core/models';
import { DOC_TYPE_LABEL } from '../../core/labels';
import { DocumentPreview } from './document-preview';
import { downloadDocument } from '../../core/document-file';

@Component({
  selector: 'app-document-view',
  imports: [RouterLink, DocumentPreview],
  template: `
    <section class="view">
      @if (loading()) {
        <div class="loading"><span class="spinner"></span> Chargement du document…</div>
      } @else if (doc(); as r) {
        <div class="sectionhead no-print">
          <div>
            <a routerLink="/documents" class="rl" style="font-size:.82rem;color:var(--ink-3)">← Mes documents</a>
            <h3>{{ typeLabel(r.doc_type) }}</h3>
            <p>Document mis à votre disposition par la RH.</p>
          </div>
          <div style="display:flex;gap:8px;flex-wrap:wrap">
            <button class="btn btn--ghost btn--sm" (click)="print()">Imprimer</button>
            <button class="btn btn--primary btn--sm" (click)="download(r)">Télécharger</button>
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

  protected loading = signal(true);
  protected doc = signal<DocumentRequest | null>(null);
  protected typeLabel = (t: string) => DOC_TYPE_LABEL[t] ?? t;

  constructor() {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    const autoPrint = this.route.snapshot.queryParamMap.get('print') === '1';
    this.docs.getRequest(id).subscribe({
      next: (r) => {
        if (r.status !== 'ready') {
          this.toast.show("Ce document n'est pas encore disponible");
          this.router.navigateByUrl('/documents');
          return;
        }
        this.doc.set(r);
        this.loading.set(false);
        if (autoPrint) setTimeout(() => window.print(), 250);
      },
      error: () => {
        this.loading.set(false);
        this.toast.show('Document introuvable');
        this.router.navigateByUrl('/documents');
      },
    });
  }

  print(): void {
    window.print();
  }

  download(r: DocumentRequest): void {
    downloadDocument(r).catch(() => this.toast.show('Téléchargement impossible'));
  }
}
