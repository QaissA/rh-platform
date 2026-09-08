import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { CreatedUser, NewUser, UpdateUser, User } from './models';

/** Admin-only user & role management (auth-service, via the gateway). */
@Injectable({ providedIn: 'root' })
export class UserAdminService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  private get url() {
    return `${this.base}/auth/users`;
  }

  list(): Observable<User[]> {
    return this.http.get<User[]>(this.url);
  }

  create(payload: NewUser): Observable<CreatedUser> {
    return this.http.post<CreatedUser>(this.url, payload);
  }

  update(id: number, payload: UpdateUser): Observable<User> {
    return this.http.patch<User>(`${this.url}/${id}`, payload);
  }

  remove(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }

  /**
   * Regenerates a fresh temporary password for a user and flags the account
   * so the next login forces a password change (like a first-time login).
   * Returns the new one-time temporary password.
   */
  resetPassword(id: number): Observable<CreatedUser> {
    return this.http.post<CreatedUser>(`${this.url}/${id}/reset-password`, {});
  }
}
