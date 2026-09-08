import { DocumentRequest } from './models';
import { DOC_TYPE_LABEL } from './labels';
import { frDate } from './format';

function f(doc: DocumentRequest, key: string): string {
  return doc.fields?.[key] ?? '';
}

function pretty(doc: DocumentRequest, key: string): string {
  const raw = f(doc, key);
  if (!raw) return '………………';
  return key.endsWith('_date') || key === 'leave_start' || key === 'leave_end' ? frDate(raw) : raw;
}

function titleOf(doc: DocumentRequest): string {
  return f(doc, 'title') || DOC_TYPE_LABEL[doc.doc_type] || 'Document';
}

function bodyHtml(doc: DocumentRequest): string {
  const p = (key: string) => escapeHtml(pretty(doc, key));
  switch (doc.doc_type) {
    case 'work_certificate':
      return `
        <p>Nous soussignés, <strong>${p('company')}</strong>, certifions que</p>
        <p class="name">${p('employee_name')}</p>
        <p>occupe le poste de <strong>${p('job_title')}</strong>${f(doc, 'start_date') ? ` depuis le <strong>${p('start_date')}</strong>` : ''}.</p>
        ${f(doc, 'purpose') ? `<p>La présente attestation est délivrée pour : ${escapeHtml(f(doc, 'purpose'))}.</p>` : ''}
      `;
    case 'salary_certificate':
      return `
        <p>Nous soussignés, <strong>${p('company')}</strong>, certifions que</p>
        <p class="name">${p('employee_name')}</p>
        <p>occupant le poste de <strong>${p('job_title')}</strong>, a perçu au titre de la période <strong>${p('period')}</strong> un salaire net de <strong>${p('net_salary')}</strong>.</p>
      `;
    case 'leave_attestation':
      return `
        <p>Nous soussignés, <strong>${p('company')}</strong>, certifions que</p>
        <p class="name">${p('employee_name')}</p>
        <p>a bénéficié d’un congé de type <strong>${p('leave_type')}</strong> du <strong>${p('leave_start')}</strong> au <strong>${p('leave_end')}</strong>${f(doc, 'days') ? `, soit <strong>${escapeHtml(f(doc, 'days'))}</strong> jour(s)` : ''}.</p>
      `;
    default:
      return `
        <p class="name">${p('employee_name')}</p>
        <p style="white-space:pre-wrap">${escapeHtml(f(doc, 'body') || '………………')}</p>
      `;
  }
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

export function documentFileName(doc: DocumentRequest): string {
  const slug = (DOC_TYPE_LABEL[doc.doc_type] ?? 'document')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `${slug}-${doc.id}.pdf`;
}

function sheetMarkup(doc: DocumentRequest): string {
  const issued = f(doc, 'issued_date') ? frDate(f(doc, 'issued_date')) : '………………';
  return `
    <article class="sheet">
      <header class="brand">
        <div>
          <div class="co">${escapeHtml(pretty(doc, 'company'))}</div>
          <div class="tag">Ressources humaines</div>
        </div>
      </header>
      <h1>${escapeHtml(titleOf(doc))}</h1>
      ${bodyHtml(doc)}
      <p>Fait pour valoir ce que de droit.</p>
      <footer class="sign">
        <div>À la date du ${escapeHtml(issued)}</div>
        <div class="signer">${escapeHtml(pretty(doc, 'signer'))}</div>
      </footer>
    </article>
  `;
}

const SHEET_CSS = `
  .sheet { width: 720px; background: #fff; color: #1a1520; padding: 40px 44px 48px;
    font-family: Georgia, "Palatino Linotype", serif; line-height: 1.65; box-sizing: border-box; }
  .brand { display: flex; gap: 12px; align-items: center; margin-bottom: 28px; }
  .co { font-size: 22px; font-weight: 700; }
  .tag { font-family: system-ui, sans-serif; font-size: 11px; letter-spacing: .12em; text-transform: uppercase; color: #6b6578; }
  h1 { font-size: 26px; text-align: center; margin: 0 0 22px; font-family: Georgia, serif; }
  p { margin: 0 0 12px; font-size: 16px; }
  .name { font-size: 22px; font-weight: 700; text-align: center; margin: 18px 0; }
  .sign { margin-top: 48px; text-align: right; font-family: system-ui, sans-serif; font-size: 14px; }
  .signer { margin-top: 36px; font-family: Georgia, serif; font-size: 18px; font-weight: 700; }
`;

/** Renders the attestation off-screen and saves it as a PDF. */
export async function downloadDocument(doc: DocumentRequest): Promise<void> {
  const [{ jsPDF }, html2canvas] = await Promise.all([
    import('jspdf'),
    import('html2canvas').then((m) => m.default),
  ]);

  const host = document.createElement('div');
  host.setAttribute('aria-hidden', 'true');
  host.style.cssText = 'position:fixed;left:-10000px;top:0;background:#fff;';
  host.innerHTML = `<style>${SHEET_CSS}</style>${sheetMarkup(doc)}`;
  document.body.appendChild(host);

  try {
    const sheet = host.querySelector('.sheet') as HTMLElement;
    const canvas = await html2canvas(sheet, { scale: 2, backgroundColor: '#ffffff' });
    const img = canvas.toDataURL('image/png');
    const pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
    const pageW = pdf.internal.pageSize.getWidth();
    const pageH = pdf.internal.pageSize.getHeight();
    const margin = 12;
    const maxW = pageW - margin * 2;
    const maxH = pageH - margin * 2;
    const ratio = canvas.height / canvas.width;
    let w = maxW;
    let h = w * ratio;
    if (h > maxH) {
      h = maxH;
      w = h / ratio;
    }
    pdf.addImage(img, 'PNG', (pageW - w) / 2, margin, w, h);
    pdf.save(documentFileName(doc));
  } finally {
    host.remove();
  }
}
