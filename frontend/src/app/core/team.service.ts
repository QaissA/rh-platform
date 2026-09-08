import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { TeamResponse } from './models';

@Injectable({ providedIn: 'root' })
export class TeamService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  getMine(): Observable<TeamResponse> {
    return this.http.get<TeamResponse>(`${this.base}/auth/teams/mine`);
  }
}
