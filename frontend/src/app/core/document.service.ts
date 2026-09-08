import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { DocumentRequest, NewDocumentRequest } from './models';

@Injectable({ providedIn: 'root' })
export class DocumentService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  getRequests(): Observable<DocumentRequest[]> {
    return this.http.get<DocumentRequest[]>(`${this.base}/admin-docs/requests`);
  }

  createRequest(payload: NewDocumentRequest): Observable<DocumentRequest> {
    return this.http.post<DocumentRequest>(`${this.base}/admin-docs/requests`, payload);
  }

  getInbox(status?: string): Observable<DocumentRequest[]> {
    const query = status ? `?status=${status}` : '';
    return this.http.get<DocumentRequest[]>(`${this.base}/admin-docs/requests/inbox${query}`);
  }

  getRequest(id: number): Observable<DocumentRequest> {
    return this.http.get<DocumentRequest>(`${this.base}/admin-docs/requests/${id}`);
  }

  updateRequest(
    id: number,
    payload: { fields?: Record<string, string>; status?: string; decision_comment?: string },
  ): Observable<DocumentRequest> {
    return this.http.patch<DocumentRequest>(`${this.base}/admin-docs/requests/${id}`, payload);
  }
}
