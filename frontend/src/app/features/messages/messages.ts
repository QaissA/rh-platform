import { Component, ElementRef, computed, effect, inject, signal, viewChild } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { ChatService } from '../../core/chat.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { ChatAttachment, ChatMessage, Conversation, TeamMember } from '../../core/models';
import { avatarClass, fullName, initials, jobTitleOf } from '../../core/format';

const ACCEPT = ['application/pdf', 'image/png', 'image/jpeg', 'image/webp'];
const MAX_BYTES = 5 * 1024 * 1024;

type ThreadItem = { kind: 'day'; label: string; key: string } | { kind: 'msg'; msg: ChatMessage };

@Component({
  selector: 'app-messages',
  imports: [FormsModule, TranslatePipe],
  templateUrl: './messages.html',
})
export class Messages {
  private chat = inject(ChatService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private route = inject(ActivatedRoute);
  private i18n = inject(I18nService);
  private log = viewChild<ElementRef<HTMLElement>>('log');

  protected conversations = this.chat.conversations;
  protected thread = this.chat.messages;
  protected activeId = this.chat.activeId;
  protected imageUrls = this.chat.imageUrls;
  protected meId = this.auth.user()?.id ?? 0;

  protected composing = signal('');
  protected listQuery = signal('');
  protected threadQuery = signal('');
  protected picking = signal(false);
  protected people = signal<TeamMember[]>([]);
  protected peopleQuery = signal('');
  protected sending = signal(false);
  protected pendingFile = signal<File | null>(null);
  protected dragging = signal(false);

  protected active = computed(() =>
    this.conversations().find((c) => c.id === this.activeId()) ?? null,
  );
  protected filteredPeople = computed(() => {
    const q = this.peopleQuery().trim().toLowerCase();
    const list = this.people();
    if (!q) return list;
    return list.filter((p) => fullName(p).toLowerCase().includes(q) || p.email.toLowerCase().includes(q));
  });
  protected filteredConversations = computed(() => {
    const q = this.listQuery().trim().toLowerCase();
    const list = this.conversations();
    if (!q) return list;
    return list.filter((c) => {
      const name = fullName(c.other).toLowerCase();
      const snip = (c.last_message?.body ?? c.last_message?.attachment?.filename ?? '').toLowerCase();
      return name.includes(q) || snip.includes(q);
    });
  });
  protected filteredThread = computed(() => {
    const q = this.threadQuery().trim().toLowerCase();
    const list = this.thread();
    if (!q) return list;
    return list.filter((m) => {
      const body = (m.body ?? '').toLowerCase();
      const file = (m.attachment?.filename ?? '').toLowerCase();
      return body.includes(q) || file.includes(q);
    });
  });
  protected items = computed<ThreadItem[]>(() => {
    this.i18n.locale();
    const out: ThreadItem[] = [];
    let lastDay = '';
    for (const msg of this.filteredThread()) {
      const key = this.dayKey(msg.created_at);
      if (key !== lastDay) {
        out.push({ kind: 'day', key, label: this.dayLabel(msg.created_at) });
        lastDay = key;
      }
      out.push({ kind: 'msg', msg });
    }
    return out;
  });
  protected canSend = computed(() =>
    (!!this.composing().trim() || !!this.pendingFile()) && !!this.activeId() && !this.sending(),
  );

  constructor() {
    this.chat.refresh();
    const userId = Number(this.route.snapshot.queryParamMap.get('user'));
    if (userId) this.openWith(userId);
    effect(() => {
      this.items();
      queueMicrotask(() => this.scrollToEnd());
    });
  }

  protected nameOf = fullName;
  protected jobOf = jobTitleOf;
  protected initialsOf = initials;
  protected av = avatarClass;
  protected accept = ACCEPT.join(',');

  snippet(c: Conversation): string {
    const last = c.last_message;
    if (!last) return this.i18n.t('chat.noMessage');
    const body = last.body?.trim();
    if (body) return body;
    if (last.attachment) return this.i18n.t('chat.attachment');
    return this.i18n.t('chat.noMessage');
  }

  openThread(c: Conversation): void {
    this.picking.set(false);
    this.threadQuery.set('');
    this.chat.select(c.id);
  }

  startPick(): void {
    this.picking.set(true);
    this.peopleQuery.set('');
    this.chat.directory().subscribe({
      next: (list) => this.people.set(list),
      error: () => this.toast.show(this.i18n.t('chat.directoryFail')),
    });
  }

  cancelPick(): void {
    this.picking.set(false);
    this.peopleQuery.set('');
  }

  openWith(userId: number): void {
    this.chat.open(userId).subscribe({
      next: () => this.picking.set(false),
      error: () => this.toast.show(this.i18n.t('chat.openFail')),
    });
  }

  onComposerKey(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.send();
    }
  }

  onFileInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0] ?? null;
    input.value = '';
    if (file) this.attach(file);
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.dragging.set(false);
    const file = event.dataTransfer?.files?.[0];
    if (file) this.attach(file);
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.dragging.set(true);
  }

  attach(file: File): void {
    if (!ACCEPT.includes(file.type)) {
      this.toast.show(this.i18n.t('chat.badType'));
      return;
    }
    if (file.size > MAX_BYTES) {
      this.toast.show(this.i18n.t('chat.tooBig'));
      return;
    }
    this.pendingFile.set(file);
  }

  clearFile(): void {
    this.pendingFile.set(null);
  }

  send(): void {
    const body = this.composing().trim();
    const file = this.pendingFile();
    if ((!body && !file) || !this.activeId() || this.sending()) return;
    this.sending.set(true);
    this.chat.send(body, file).subscribe({
      next: () => {
        this.composing.set('');
        this.pendingFile.set(null);
        this.sending.set(false);
      },
      error: (err: unknown) => {
        this.sending.set(false);
        this.toast.show(this.errorText(err, this.i18n.t('chat.sendFail')));
      },
    });
  }

  download(m: ChatMessage): void {
    this.chat.download(m);
  }

  mine(m: ChatMessage): boolean {
    return m.sender_id === this.meId;
  }

  isImage(file: ChatAttachment): boolean {
    return file.content_type.startsWith('image/');
  }

  previewOf(m: ChatMessage): string | undefined {
    return this.imageUrls()[m.id];
  }

  fileSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  when(iso: string): string {
    const d = new Date(iso);
    return new Intl.DateTimeFormat(this.i18n.locale(), { hour: '2-digit', minute: '2-digit' }).format(d);
  }

  trackItem(item: ThreadItem): string {
    return item.kind === 'day' ? `d-${item.key}` : `m-${item.msg.id}`;
  }

  private dayKey(iso: string): string {
    const d = new Date(iso);
    return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
  }

  private dayLabel(iso: string): string {
    const d = new Date(iso);
    const today = new Date();
    const yesterday = new Date();
    yesterday.setDate(today.getDate() - 1);
    if (this.sameDay(d, today)) return this.i18n.t('chat.today');
    if (this.sameDay(d, yesterday)) return this.i18n.t('chat.yesterday');
    return new Intl.DateTimeFormat(this.i18n.locale(), { weekday: 'long', day: 'numeric', month: 'long' }).format(d);
  }

  private sameDay(a: Date, b: Date): boolean {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  private scrollToEnd(): void {
    const el = this.log()?.nativeElement;
    if (el) el.scrollTop = el.scrollHeight;
  }

  private errorText(err: unknown, fallback: string): string {
    if (!(err instanceof HttpErrorResponse)) return fallback;
    const body = err.error;
    if (typeof body?.error === 'string') return body.error;
    if (Array.isArray(body?.errors) && body.errors.length) return String(body.errors[0]);
    return fallback;
  }
}
