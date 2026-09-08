import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { NewTeam, TeamDetail, TeamSummary, UpdateTeam } from './models';

/** Admin-only team management (auth-service, via the gateway). */
@Injectable({ providedIn: 'root' })
export class TeamAdminService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  private get url() {
    return `${this.base}/auth/teams`;
  }

  list(): Observable<TeamSummary[]> {
    return this.http.get<TeamSummary[]>(this.url);
  }

  get(id: number): Observable<TeamDetail> {
    return this.http.get<TeamDetail>(`${this.url}/${id}`);
  }

  create(payload: NewTeam): Observable<TeamSummary> {
    return this.http.post<TeamSummary>(this.url, payload);
  }

  update(id: number, payload: UpdateTeam): Observable<TeamSummary> {
    return this.http.patch<TeamSummary>(`${this.url}/${id}`, payload);
  }

  remove(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
