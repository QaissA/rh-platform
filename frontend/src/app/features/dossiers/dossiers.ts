import { Component, computed, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { UserAdminService } from '../../core/user-admin.service';
import { ProfileService } from '../../core/profile.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { User } from '../../core/models';
import { fullName } from '../../core/format';

@Component({
  selector: 'app-dossiers',
  imports: [RouterLink, TranslatePipe],
  templateUrl: './dossiers.html',
})
export class Dossiers {
  private usersApi = inject(UserAdminService);
  private profiles = inject(ProfileService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected users = signal<User[]>([]);
  protected busyId = signal<number | null>(null);

  protected pending = computed(() => this.users().filter((u) => !!u.pending_job_title));

  protected name = (u: User) => fullName(u);
  protected roleLabel = (r: string) => this.i18n.t('status.role.' + r);
  protected requestMeta = (u: User) =>
    this.i18n.t('dossiers.requestMeta', {
      pending: u.pending_job_title ?? '',
      current: u.job_title || this.i18n.t('common.dash'),
    });

  constructor() {
    this.reload();
  }

  accept(u: User): void {
    this.busyId.set(u.id);
    this.profiles.acceptJobTitle(u.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.toast.show(this.i18n.t('dossiers.jobAccepted', { name: this.name(u) }));
        this.reload();
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show(this.i18n.t('dossiers.acceptFail'));
      },
    });
  }

  reject(u: User): void {
    this.busyId.set(u.id);
    this.profiles.rejectJobTitle(u.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.toast.show(this.i18n.t('dossiers.rejectedFor', { name: this.name(u) }));
        this.reload();
      },
      error: () => {
        this.busyId.set(null);
        this.toast.show(this.i18n.t('dossiers.rejectFail'));
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
