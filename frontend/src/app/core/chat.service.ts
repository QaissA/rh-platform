import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { API_BASE_URL } from './api';
import { CableService, ChatPush } from './cable.service';
import { AuthService } from './auth.service';
import { ChatMessage, Conversation, TeamMember } from './models';

@Injectable({ providedIn: 'root' })
export class ChatService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);
  private cable = inject(CableService);
  private auth = inject(AuthService);

  readonly conversations = signal<Conversation[]>([]);
  readonly messages = signal<ChatMessage[]>([]);
  readonly activeId = signal<number | null>(null);
  readonly imageUrls = signal<Record<number, string>>({});
  readonly unreadTotal = computed(() =>
    this.conversations().reduce((sum, c) => sum + (c.unread_count || 0), 0),
  );
  private fetchingImages = new Set<number>();

  constructor() {
    this.cable.setHandler((payload) => this.handlePush(payload));
    if (this.auth.token) this.start();
  }

  start(): void {
    this.cable.connect();
    this.refresh();
  }

  stop(): void {
    this.cable.disconnect();
    this.conversations.set([]);
    this.messages.set([]);
    this.activeId.set(null);
    this.revokeImages();
  }

  refresh(): void {
    this.http.get<Conversation[]>(`${this.base}/auth/conversations`).subscribe({
      next: (list) => this.conversations.set(list),
      error: () => undefined,
    });
  }

  directory(): Observable<TeamMember[]> {
    return this.http.get<TeamMember[]>(`${this.base}/auth/directory`);
  }

  open(userId: number): Observable<Conversation> {
    return this.http.post<Conversation>(`${this.base}/auth/conversations`, { user_id: userId }).pipe(
      tap((conv) => {
        this.upsert(conv);
        this.select(conv.id);
      }),
    );
  }

  select(id: number): void {
    this.activeId.set(id);
    this.http.get<ChatMessage[]>(`${this.base}/auth/conversations/${id}/messages`).subscribe({
      next: (list) => {
        this.messages.set(list);
        this.cacheImages(list);
      },
      error: () => this.messages.set([]),
    });
    this.http.post<Conversation>(`${this.base}/auth/conversations/${id}/read`, {}).subscribe({
      next: (conv) => this.upsert({ ...conv, unread_count: 0 }),
      error: () => undefined,
    });
  }

  send(body: string, file?: File | null): Observable<ChatMessage> {
    const id = this.activeId();
    if (!id) throw new Error('No conversation');
    const url = `${this.base}/auth/conversations/${id}/messages`;
    const req$ = file
      ? this.http.post<ChatMessage>(url, this.toForm(body, file))
      : this.http.post<ChatMessage>(url, { body });
    return req$.pipe(
      tap((msg) => {
        this.messages.update((list) => (list.some((m) => m.id === msg.id) ? list : [...list, msg]));
        this.cacheImages([msg]);
        const conv = this.conversations().find((c) => c.id === id);
        if (conv) this.upsert({ ...conv, last_message: msg });
      }),
    );
  }

  fileUrl(msg: ChatMessage, download = false): string {
    const path = msg.attachment?.url ?? `/conversations/${msg.conversation_id}/messages/${msg.id}/file`;
    return `${this.base}/auth${path}${download ? '?download=1' : ''}`;
  }

  download(msg: ChatMessage): void {
    this.http.get(this.fileUrl(msg, true), { responseType: 'blob' }).subscribe({
      next: (blob) => {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = msg.attachment?.filename ?? 'document';
        a.click();
        URL.revokeObjectURL(url);
      },
    });
  }

  private toForm(body: string, file: File): FormData {
    const data = new FormData();
    if (body.trim()) data.append('body', body.trim());
    data.append('file', file, file.name);
    return data;
  }

  private handlePush(payload: ChatPush): void {
    const me = this.auth.user()?.id;
    this.conversations.update((list) => {
      const existing = list.find((c) => c.id === payload.conversation_id);
      if (!existing) {
        this.refresh();
        return list;
      }
      const mine = payload.message.sender_id === me;
      const open = this.activeId() === payload.conversation_id;
      const unread = mine || open ? existing.unread_count : existing.unread_count + 1;
      const next = { ...existing, last_message: payload.message, unread_count: unread };
      return [next, ...list.filter((c) => c.id !== next.id)];
    });
    if (this.activeId() === payload.conversation_id) {
      this.messages.update((list) =>
        list.some((m) => m.id === payload.message.id) ? list : [...list, payload.message],
      );
      this.cacheImages([payload.message]);
      if (payload.message.sender_id !== me) {
        this.http.post(`${this.base}/auth/conversations/${payload.conversation_id}/read`, {}).subscribe();
      }
    }
  }

  private cacheImages(messages: ChatMessage[]): void {
    for (const msg of messages) {
      if (!msg.attachment?.content_type.startsWith('image/')) continue;
      if (this.imageUrls()[msg.id] || this.fetchingImages.has(msg.id)) continue;
      this.fetchingImages.add(msg.id);
      this.http.get(this.fileUrl(msg), { responseType: 'blob' }).subscribe({
        next: (blob) => {
          const url = URL.createObjectURL(blob);
          this.imageUrls.update((map) => ({ ...map, [msg.id]: url }));
        },
        error: () => this.fetchingImages.delete(msg.id),
        complete: () => this.fetchingImages.delete(msg.id),
      });
    }
  }

  private revokeImages(): void {
    Object.values(this.imageUrls()).forEach((url) => URL.revokeObjectURL(url));
    this.imageUrls.set({});
    this.fetchingImages.clear();
  }

  private upsert(conv: Conversation): void {
    this.conversations.update((list) => {
      const rest = list.filter((c) => c.id !== conv.id);
      return [conv, ...rest];
    });
  }
}
