import { Injectable, inject, signal } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, map, tap } from 'rxjs/operators';
import { UserAdminService } from './user-admin.service';
import { TeamService } from './team.service';
import { AuthService } from './auth.service';
import { I18nService } from './i18n.service';
import { TeamMember, User } from './models';
import { fullName, initials, jobTitleOf } from './format';

/** Directory of people the current user is allowed to resolve by id. */
@Injectable({ providedIn: 'root' })
export class PeopleService {
  private userAdmin = inject(UserAdminService);
  private team = inject(TeamService);
  private auth = inject(AuthService);
  private i18n = inject(I18nService);

  private directory = signal<Map<number, TeamMember>>(new Map());

  load(): Observable<Map<number, TeamMember>> {
    const me = this.auth.user();
    if (me?.role === 'admin' || me?.role === 'rh') {
      return this.userAdmin.list().pipe(
        map((users) => {
          const next = new Map<number, TeamMember>();
          users.forEach((u) => next.set(u.id, this.toMember(u)));
          return next;
        }),
        tap((next) => this.directory.set(next)),
        catchError(() => of(this.remember(this.selfMap(me)))),
      );
    }

    return this.team.getMine().pipe(
      map((res) => {
        const next = this.selfMap(me);
        (res.members ?? []).forEach((m) => next.set(m.id, m));
        return next;
      }),
      tap((next) => this.directory.set(next)),
      catchError(() => of(this.remember(this.selfMap(me)))),
    );
  }

  get(id: number): TeamMember | undefined {
    return this.directory().get(id);
  }

  nameOf(id: number): string {
    const member = this.get(id);
    return member ? fullName(member) : this.i18n.t('common.collaboratorN', { id });
  }

  jobTitleOf(id: number): string | null {
    return jobTitleOf(this.get(id));
  }

  initialsOf(id: number): string {
    const member = this.get(id);
    return member ? initials(member) : '?';
  }

  toMember(user: User | TeamMember): TeamMember {
    return {
      id: user.id,
      email: user.email,
      first_name: user.first_name ?? null,
      last_name: user.last_name ?? null,
      role: user.role,
      job_title: user.job_title ?? null,
    };
  }

  private selfMap(me: User | null | undefined): Map<number, TeamMember> {
    const next = new Map<number, TeamMember>();
    if (me) next.set(me.id, this.toMember(me));
    return next;
  }

  private remember(next: Map<number, TeamMember>): Map<number, TeamMember> {
    this.directory.set(next);
    return next;
  }
}
