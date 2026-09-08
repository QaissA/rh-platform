import { Injectable, inject } from '@angular/core';
import { createConsumer, type Consumer, type Subscription } from '@rails/actioncable';
import { API_BASE_URL } from './api';
import { AuthService } from './auth.service';
import { ChatMessage } from './models';

export interface ChatPush {
  type: string;
  conversation_id: number;
  message: ChatMessage;
}

@Injectable({ providedIn: 'root' })
export class CableService {
  private auth = inject(AuthService);
  private base = inject(API_BASE_URL);
  private consumer: Consumer | null = null;
  private sub: Subscription | null = null;
  private handler: ((payload: ChatPush) => void) | null = null;

  setHandler(fn: (payload: ChatPush) => void): void {
    this.handler = fn;
  }

  connect(): void {
    this.disconnect();
    const token = this.auth.token;
    if (!token) return;
    const ws = this.base.replace(/^http/, 'ws');
    this.consumer = createConsumer(`${ws}/cable?token=${encodeURIComponent(token)}`);
    this.sub = this.consumer.subscriptions.create(
      { channel: 'ChatChannel' },
      {
        received: (data: unknown) => {
          const payload = data as ChatPush;
          if (payload?.type === 'message') this.handler?.(payload);
        },
      },
    );
  }

  disconnect(): void {
    this.sub?.unsubscribe();
    this.sub = null;
    this.consumer?.disconnect();
    this.consumer = null;
  }
}
