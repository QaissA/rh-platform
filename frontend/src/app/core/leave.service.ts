import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { LeaveBalance, LeaveRequest, LeaveStatus, NewLeaveRequest } from './models';

@Injectable({ providedIn: 'root' })
export class LeaveService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  getBalance(): Observable<LeaveBalance> {
    return this.http.get<LeaveBalance>(`${this.base}/leave/balance`);
  }

  getRequests(): Observable<LeaveRequest[]> {
    return this.http.get<LeaveRequest[]>(`${this.base}/leave/requests`);
  }

  createRequest(payload: NewLeaveRequest): Observable<LeaveRequest> {
    return this.http.post<LeaveRequest>(`${this.base}/leave/requests`, payload);
  }

  /** Manager/RH/admin view: requests in their validation scope. */
  getTeamRequests(status?: LeaveStatus | LeaveStatus[]): Observable<LeaveRequest[]> {
    const value = Array.isArray(status) ? status.join(',') : status;
    const query = value ? `?status=${value}` : '';
    return this.http.get<LeaveRequest[]>(`${this.base}/leave/requests/team${query}`);
  }

  approve(id: number): Observable<LeaveRequest> {
    return this.http.patch<LeaveRequest>(`${this.base}/leave/requests/${id}/approve`, {});
  }

  reject(id: number, comment?: string): Observable<LeaveRequest> {
    return this.http.patch<LeaveRequest>(`${this.base}/leave/requests/${id}/reject`, { comment });
  }
}
