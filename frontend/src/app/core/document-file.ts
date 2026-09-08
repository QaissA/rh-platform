import { DocumentRequest } from './models';
import { I18nService } from './i18n.service';

function f(doc: DocumentRequest, key: string): string {
  return doc.fields?.[key] ?? '';
}

function pretty(doc: DocumentRequest, key: string, i18n: I18nService): string {
  const raw = f(doc, key);
  if (!raw) return i18n.t('docSheet.blank');
  return key.endsWith('_date') || key === 'leave_start' || key === 'leave_end' ? i18n.formatDate(raw) : raw;
}

function titleOf(doc: DocumentRequest, i18n: I18nService): string {
  return f(doc, 'title') || i18n.t(`docType.${doc.doc_type}`) || i18n.t('common.document');
}

function bodyHtml(doc: DocumentRequest, i18n: I18nService): string {
  const p = (key: string) => escapeHtml(pretty(doc, key, i18n));
  const company = `<strong>${p('company')}</strong>`;
  switch (doc.doc_type) {
    case 'work_certificate':
      return `
        <p>${i18n.t('docSheet.weCertify', { company })}</p>
        <p class="name">${p('employee_name')}</p>
        <p>${i18n.t('docSheet.occupies', { title: `<strong>${p('job_title')}</strong>` })}${
          f(doc, 'start_date') ? ` ${i18n.t('docSheet.since', { date: `<strong>${p('start_date')}</strong>` })}` : ''
        }.</p>
        ${f(doc, 'purpose') ? `<p>${i18n.t('docSheet.issuedFor', { purpose: escapeHtml(f(doc, 'purpose')) })}</p>` : ''}
      `;
    case 'salary_certificate':
      return `
        <p>${i18n.t('docSheet.weCertify', { company })}</p>
        <p class="name">${p('employee_name')}</p>
        <p>${i18n.t('docSheet.occupying', {
          title: `<strong>${p('job_title')}</strong>`,
          period: `<strong>${p('period')}</strong>`,
          salary: `<strong>${p('net_salary')}</strong>`,
        })}</p>
      `;
    case 'leave_attestation':
      return `
        <p>${i18n.t('docSheet.weCertify', { company })}</p>
        <p class="name">${p('employee_name')}</p>
        <p>${i18n.t('docSheet.hadLeave', {
          type: `<strong>${p('leave_type')}</strong>`,
          start: `<strong>${p('leave_start')}</strong>`,
          end: `<strong>${p('leave_end')}</strong>`,
        })}${f(doc, 'days') ? i18n.t('docSheet.daysWorth', { days: `<strong>${escapeHtml(f(doc, 'days'))}</strong>` }) : ''}.</p>
      `;
    default:
      return `
        <p class="name">${p('employee_name')}</p>
        <p style="white-space:pre-wrap">${escapeHtml(f(doc, 'body') || i18n.t('docSheet.blank'))}</p>
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

export function documentFileName(doc: DocumentRequest, i18n: I18nService): string {
  const slug = (i18n.t(`docType.${doc.doc_type}`) || 'document')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  return `${slug || 'document'}-${doc.id}.pdf`;
}

function sheetMarkup(doc: DocumentRequest, i18n: I18nService): string {
  const issued = f(doc, 'issued_date') ? i18n.formatDate(f(doc, 'issued_date')) : i18n.t('docSheet.blank');
  return `
    <article class="sheet">
      <header class="brand">
        <div>
          <div class="co">${escapeHtml(pretty(doc, 'company', i18n))}</div>
          <div class="tag">${escapeHtml(i18n.t('docSheet.hr'))}</div>
        </div>
      </header>
      <h1>${escapeHtml(titleOf(doc, i18n))}</h1>
      ${bodyHtml(doc, i18n)}
      <p>${escapeHtml(i18n.t('docSheet.closing'))}</p>
      <footer class="sign">
        <div>${i18n.t('docSheet.issuedOn', { date: escapeHtml(issued) })}</div>
        <div class="signer">${escapeHtml(pretty(doc, 'signer', i18n))}</div>
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
export async function downloadDocument(doc: DocumentRequest, i18n: I18nService): Promise<void> {
  const [{ jsPDF }, html2canvas] = await Promise.all([
    import('jspdf'),
    import('html2canvas').then((m) => m.default),
  ]);

  const host = document.createElement('div');
  host.setAttribute('aria-hidden', 'true');
  host.style.cssText = 'position:fixed;left:-10000px;top:0;background:#fff;';
  host.innerHTML = `<style>${SHEET_CSS}</style>${sheetMarkup(doc, i18n)}`;
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
    pdf.save(documentFileName(doc, i18n));
  } finally {
    host.remove();
  }
}
