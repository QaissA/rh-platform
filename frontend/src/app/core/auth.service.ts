import { Injectable, Injector, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { API_BASE_URL } from './api';
import { LoginResponse, User } from './models';
import { NotificationService } from './notification.service';
import { InboxBadgeService } from './inbox-badge.service';

const TOKEN_KEY = 'alize.token';
const USER_KEY = 'alize.user';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);
  private readonly notifs = inject(NotificationService);
  private readonly badges = inject(InboxBadgeService);
  private readonly injector = inject(Injector);

  private _user = signal<User | null>(readUser());
  private _token = signal<string | null>(localStorage.getItem(TOKEN_KEY));
  // The password just used to sign in, kept in memory only for the forced
  // first-login change so the user doesn't have to retype their temporary one.
  private _tempPassword = signal<string | null>(null);

  readonly user = this._user.asReadonly();
  readonly isAuthenticated = computed(() => !!this._token());
  // True for admin-created accounts that still carry their temporary password.
  readonly mustChangePassword = computed(() => !!this._user()?.must_change_password);
  // Whether we captured the temporary password at login (forced-change flow).
  readonly hasTempPassword = computed(() => !!this._tempPassword());

  get token(): string | null {
    return this._token();
  }

  login(email: string, password: string): Observable<LoginResponse> {
    return this.http
      .post<LoginResponse>(`${this.base}/auth/login`, { email, password })
      .pipe(
        tap((res) => {
          this.notifs.clear();
          this.badges.clear();
          this.persist(res);
          this.startChat();
          // Remember the temporary password so the forced change screen can
          // reuse it without asking the user to re-enter it.
          this._tempPassword.set(res.user.must_change_password ? password : null);
        }),
      );
  }

  // Sets a new password; on success the returned user clears must_change_password.
  changePassword(currentPassword: string, newPassword: string): Observable<User> {
    return this.http
      .patch<User>(`${this.base}/auth/password`, {
        current_password: currentPassword,
        new_password: newPassword,
      })
      .pipe(tap((user) => this.finishPasswordChange(user)));
  }

  // Forced first-login change: reuses the temporary password captured at login.
  changePasswordForced(newPassword: string): Observable<User> {
    return this.changePassword(this._tempPassword() ?? '', newPassword);
  }

  logout(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    this._token.set(null);
    this._user.set(null);
    this._tempPassword.set(null);
    this.notifs.clear();
    this.badges.clear();
    this.stopChat();
  }

  private finishPasswordChange(user: User): void {
    this._tempPassword.set(null); // temporary password is no longer valid
    this.persistUser(user);
  }

  private persist(res: LoginResponse): void {
    localStorage.setItem(TOKEN_KEY, res.token);
    this._token.set(res.token);
    this.persistUser(res.user);
  }

  private persistUser(user: User): void {
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    this._user.set(user);
  }

  private startChat(): void {
    import('./chat.service').then((m) => this.injector.get(m.ChatService).start());
  }

  private stopChat(): void {
    import('./chat.service').then((m) => this.injector.get(m.ChatService).stop());
  }
}

function readUser(): User | null {
  const raw = localStorage.getItem(USER_KEY);
  try {
    return raw ? (JSON.parse(raw) as User) : null;
  } catch {
    return null;
  }
}
