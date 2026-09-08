import { Component, inject, signal, viewChild } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ProfileService } from '../../core/profile.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { UserProfile } from '../../core/models';
import { SignaturePad } from '../../shared/signature-pad';

const MIN_LENGTH = 8;

@Component({
  selector: 'app-settings',
  imports: [FormsModule, SignaturePad, TranslatePipe],
  templateUrl: './settings.html',
})
export class Settings {
  private profiles = inject(ProfileService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected savingAddress = signal(false);
  protected savingTitle = signal(false);
  protected savingPassword = signal(false);
  protected savingSig = signal(false);
  protected pad = viewChild(SignaturePad);

  protected profile = signal<UserProfile | null>(null);
  protected requestedTitle = '';
  protected addressLine = '';
  protected postalCode = '';
  protected city = '';
  protected country = 'FR';

  protected currentPassword = '';
  protected newPassword = '';
  protected confirmPassword = '';
  protected pwdError = signal<string | null>(null);

  protected tooShort(): boolean {
    return this.newPassword.length > 0 && this.newPassword.length < MIN_LENGTH;
  }
  protected mismatch(): boolean {
    return this.confirmPassword.length > 0 && this.newPassword !== this.confirmPassword;
  }

  constructor() {
    this.profiles.getMine().subscribe({
      next: (p) => {
        this.profile.set(p);
        this.addressLine = p.address_line ?? '';
        this.postalCode = p.postal_code ?? '';
        this.city = p.city ?? '';
        this.country = p.country || 'FR';
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  requestTitle(): void {
    const title = this.requestedTitle.trim();
    if (!title || this.savingTitle()) return;
    this.savingTitle.set(true);
    this.profiles.updateMine({ pending_job_title: title }).subscribe({
      next: (p) => {
        this.profile.set(p);
        this.requestedTitle = '';
        this.savingTitle.set(false);
        this.toast.show(this.i18n.t('settings.jobSent'));
      },
      error: () => {
        this.savingTitle.set(false);
        this.toast.show(this.i18n.t('settings.jobSendFail'));
      },
    });
  }

  cancelTitle(): void {
    this.savingTitle.set(true);
    this.profiles.updateMine({ pending_job_title: null }).subscribe({
      next: (p) => {
        this.profile.set(p);
        this.savingTitle.set(false);
        this.toast.show(this.i18n.t('settings.cancelled'));
      },
      error: () => {
        this.savingTitle.set(false);
        this.toast.show(this.i18n.t('settings.cancelFail'));
      },
    });
  }

  saveAddress(): void {
    if (this.savingAddress()) return;
    this.savingAddress.set(true);
    this.profiles
      .updateMine({
        address_line: this.addressLine.trim(),
        postal_code: this.postalCode.trim(),
        city: this.city.trim(),
        country: this.country.trim() || 'FR',
      })
      .subscribe({
        next: (p) => {
          this.profile.set(p);
          this.savingAddress.set(false);
          this.toast.show(this.i18n.t('settings.addressSaved'));
        },
        error: () => {
          this.savingAddress.set(false);
          this.toast.show(this.i18n.t('settings.saveFail'));
        },
      });
  }

  changePassword(): void {
    if (this.savingPassword() || this.tooShort() || this.mismatch() || !this.newPassword) return;
    this.savingPassword.set(true);
    this.pwdError.set(null);
    this.auth.changePassword(this.currentPassword, this.newPassword).subscribe({
      next: () => {
        this.savingPassword.set(false);
        this.currentPassword = '';
        this.newPassword = '';
        this.confirmPassword = '';
        this.toast.show(this.i18n.t('settings.passwordUpdated'));
      },
      error: (err) => {
        this.savingPassword.set(false);
        this.pwdError.set(err?.error?.error || this.i18n.t('settings.passwordFail'));
      },
    });
  }

  canDraw(): boolean {
    const p = this.profile();
    return !p?.signature_png || !p.signature_locked;
  }

  saveSignature(): void {
    const png = this.pad()?.snapshot();
    if (!png || this.savingSig()) return;
    this.savingSig.set(true);
    this.profiles.updateMine({ signature_png: png }).subscribe({
      next: (p) => {
        this.profile.set(p);
        this.savingSig.set(false);
        this.toast.show(this.i18n.t('settings.sigSaved'));
      },
      error: (err) => {
        this.savingSig.set(false);
        this.toast.show(err?.error?.error || this.i18n.t('settings.saveFail'));
      },
    });
  }
}
