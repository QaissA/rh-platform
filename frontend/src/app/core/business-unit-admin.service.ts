import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { BusinessUnit, NewBusinessUnit, UpdateBusinessUnit } from './models';

/** Admin-only business-unit management (auth-service, via the gateway). */
@Injectable({ providedIn: 'root' })
export class BusinessUnitAdminService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  private get url() {
    return `${this.base}/auth/business-units`;
  }

  list(): Observable<BusinessUnit[]> {
    return this.http.get<BusinessUnit[]>(this.url);
  }

  create(payload: NewBusinessUnit): Observable<BusinessUnit> {
    return this.http.post<BusinessUnit>(this.url, payload);
  }

  update(id: number, payload: UpdateBusinessUnit): Observable<BusinessUnit> {
    return this.http.patch<BusinessUnit>(`${this.url}/${id}`, payload);
  }

  remove(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
