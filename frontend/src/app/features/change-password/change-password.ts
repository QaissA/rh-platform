import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { LangSwitcher } from '../../shared/lang-switcher';

const MIN_LENGTH = 8;

@Component({
  selector: 'app-change-password',
  imports: [FormsModule, TranslatePipe, LangSwitcher],
  templateUrl: './change-password.html',
  styleUrl: './change-password.css',
})
export class ChangePassword {
  private auth = inject(AuthService);
  private router = inject(Router);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  // When we captured the temporary password at login, the user goes straight to
  // choosing a new password — no need to retype the temporary one.
  protected knowsTempPassword = this.auth.hasTempPassword();
  protected currentPassword = signal('');
  protected newPassword = signal('');
  protected confirmPassword = signal('');
  protected loading = signal(false);
  protected error = signal<string | null>(null);

  // Client-side mirror of the backend rules, so we can guide before submitting.
  protected tooShort = computed(() => this.newPassword().length < MIN_LENGTH);
  protected mismatch = computed(
    () => this.confirmPassword().length > 0 && this.newPassword() !== this.confirmPassword(),
  );
  protected sameAsCurrent = computed(
    () =>
      !this.knowsTempPassword &&
      this.newPassword().length > 0 &&
      this.newPassword() === this.currentPassword(),
  );
  protected canSubmit = computed(
    () =>
      !this.loading() &&
      (this.knowsTempPassword || this.currentPassword().length > 0) &&
      !this.tooShort() &&
      !this.mismatch() &&
      !this.sameAsCurrent(),
  );

  submit(): void {
    if (!this.canSubmit()) return;
    this.loading.set(true);
    this.error.set(null);
    const request$ = this.knowsTempPassword
      ? this.auth.changePasswordForced(this.newPassword())
      : this.auth.changePassword(this.currentPassword(), this.newPassword());
    request$.subscribe({
      next: () => {
        this.toast.show(this.i18n.t('settings.passwordUpdated'));
        this.router.navigateByUrl('/dashboard');
      },
      error: (err) => {
        this.loading.set(false);
        this.error.set(this.errorText(err));
      },
    });
  }

  private errorText(err: unknown): string {
    const e = err as { status?: number; error?: { error?: string; errors?: string[] } };
    if (e?.status === 0) {
      return this.i18n.t('login.offline');
    }
    return e?.error?.error || e?.error?.errors?.join(', ') || this.i18n.t('password.fail');
  }
}
