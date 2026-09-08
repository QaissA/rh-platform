declare module '@rails/actioncable' {
  export interface Subscription {
    unsubscribe(): void;
  }

  export interface Consumer {
    subscriptions: {
      create(
        channel: string | { channel: string },
        mixins: { received?: (data: unknown) => void; connected?: () => void; disconnected?: () => void },
      ): Subscription;
    };
    disconnect(): void;
  }

  export function createConsumer(url?: string): Consumer;
}
