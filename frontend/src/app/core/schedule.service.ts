import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { NewPresence, ScheduleEntry, ScheduleResponse } from './models';

@Injectable({ providedIn: 'root' })
export class ScheduleService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  /** Team "emploi du temps": every member's daily state over [start, end]. */
  getSchedule(start: string, end: string): Observable<ScheduleResponse> {
    const params = new HttpParams().set('start', start).set('end', end);
    return this.http.get<ScheduleResponse>(`${this.base}/leave/schedule`, { params });
  }

  /** Declare the current user's work location (on_site|remote) over a range. */
  declarePresence(payload: NewPresence): Observable<{ entries: ScheduleEntry[] }> {
    return this.http.post<{ entries: ScheduleEntry[] }>(`${this.base}/leave/presences`, payload);
  }
}
