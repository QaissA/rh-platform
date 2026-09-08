import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { UserAdminService } from '../../core/user-admin.service';
import { ProfileService } from '../../core/profile.service';
import { ToastService } from '../../core/toast.service';
import { User } from '../../core/models';
import { fullName } from '../../core/format';
import { ROLE_LABEL } from '../../core/labels';

@Component({
  selector: 'app-dossiers',
  imports: [RouterLink],
  templateUrl: './dossiers.html',
})
export class Dossiers {
  private usersApi = inject(UserAdminService);
  private profiles = inject(ProfileService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected users = signal<User[]>([]);
  protected busyId = signal<number | null>(null);

  protected pending = computed(() => this.users().filter((u) => !!u.pending_job_title));

  protected name = (u: User) => fullName(u);
  protected roleLabel = (r: string) => ROLE_LABEL[r] ?? r;

  constructor() {
    this.reload();
  }

  accept(u: User): void {
    this.busyId.set(u.id);
    this.profiles.acceptJobTitle(u.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.toast.show(`Poste confirmé pour ${this.name(u)}`);
        this.reload();
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show('Validation impossible');
      },
    });
  }

  reject(u: User): void {
    this.busyId.set(u.id);
    this.profiles.rejectJobTitle(u.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.toast.show(`Demande refusée pour ${this.name(u)}`);
        this.reload();
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show('Refus impossible');
      },
    });
  }

  private reload(): void {
    this.loading.set(true);
    this.usersApi.list().subscribe({
      next: (list) => {
        this.users.set(list);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }
}
