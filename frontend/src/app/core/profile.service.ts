import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { API_BASE_URL } from './api';
import { UpdateDossier, UpdateProfile, UserDossier, UserProfile } from './models';

@Injectable({ providedIn: 'root' })
export class ProfileService {
  private http = inject(HttpClient);
  private base = inject(API_BASE_URL);

  getMine(): Observable<UserProfile> {
    return this.http.get<UserProfile>(`${this.base}/auth/profile`);
  }

  updateMine(payload: UpdateProfile): Observable<UserProfile> {
    return this.http.patch<UserProfile>(`${this.base}/auth/profile`, payload);
  }

  getDossier(id: number): Observable<UserDossier> {
    return this.http.get<UserDossier>(`${this.base}/auth/users/${id}`);
  }

  updateDossier(id: number, payload: UpdateDossier): Observable<UserDossier> {
    return this.http.patch<UserDossier>(`${this.base}/auth/users/${id}`, payload);
  }

  acceptJobTitle(id: number): Observable<UserDossier> {
    return this.http.post<UserDossier>(`${this.base}/auth/users/${id}/job-title/accept`, {});
  }

  rejectJobTitle(id: number, comment?: string): Observable<UserDossier> {
    return this.http.post<UserDossier>(`${this.base}/auth/users/${id}/job-title/reject`, { comment });
  }

  unlockSignature(id: number): Observable<UserDossier> {
    return this.http.post<UserDossier>(`${this.base}/auth/users/${id}/signature/unlock`, {});
  }
}
