import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { NewProject, Project, UpdateProject } from './models';

/** Admin-only project management (auth-service, via the gateway). */
@Injectable({ providedIn: 'root' })
export class ProjectAdminService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  private get url() {
    return `${this.base}/auth/projects`;
  }

  /** All projects, or only those within a given business unit. */
  list(businessUnitId?: number): Observable<Project[]> {
    const query = businessUnitId ? `?business_unit_id=${businessUnitId}` : '';
    return this.http.get<Project[]>(`${this.url}${query}`);
  }

  create(payload: NewProject): Observable<Project> {
    return this.http.post<Project>(this.url, payload);
  }

  update(id: number, payload: UpdateProject): Observable<Project> {
    return this.http.patch<Project>(`${this.url}/${id}`, payload);
  }

  remove(id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${id}`);
  }
}
