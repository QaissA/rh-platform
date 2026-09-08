import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { ProfileService } from '../../core/profile.service';
import { UserAdminService } from '../../core/user-admin.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { ContractType, UserDossier } from '../../core/models';
import { CONTRACT_TYPES } from '../../core/labels';

@Component({
  selector: 'app-dossier-edit',
  imports: [FormsModule, RouterLink, TranslatePipe],
  templateUrl: './dossier-edit.html',
})
export class DossierEdit {
  private route = inject(ActivatedRoute);
  private profiles = inject(ProfileService);
  private usersApi = inject(UserAdminService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected saving = signal(false);
  protected resetting = signal(false);
  protected unlocking = signal(false);
  protected tempPassword = signal<string | null>(null);
  protected dossier = signal<UserDossier | null>(null);

  protected firstName = '';
  protected lastName = '';
  protected jobTitle = '';
  protected addressLine = '';
  protected postalCode = '';
  protected city = '';
  protected country = 'FR';
  protected salaryEuros: number | null = null;
  protected contractType: ContractType | '' = '';
  protected hiredOn = '';
  protected iban = '';

  protected contracts = CONTRACT_TYPES;
  protected contractLabel = (c: string) => this.i18n.t('status.contract.' + c);

  constructor() {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.profiles.getDossier(id).subscribe({
      next: (d) => {
        this.dossier.set(d);
        this.firstName = d.first_name ?? '';
        this.lastName = d.last_name ?? '';
        this.jobTitle = d.job_title ?? '';
        this.addressLine = d.address_line ?? '';
        this.postalCode = d.postal_code ?? '';
        this.city = d.city ?? '';
        this.country = d.country || 'FR';
        this.salaryEuros = d.salary_cents != null ? d.salary_cents / 100 : null;
        this.contractType = d.contract_type ?? '';
        this.hiredOn = d.hired_on ?? '';
        this.iban = d.iban ?? '';
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  save(): void {
    const d = this.dossier();
    if (!d || this.saving()) return;
    this.saving.set(true);
    const cents =
      this.salaryEuros === null || this.salaryEuros === undefined
        ? null
        : Math.round(Number(this.salaryEuros) * 100);
    this.profiles
      .updateDossier(d.id, {
        first_name: this.firstName.trim(),
        last_name: this.lastName.trim(),
        job_title: this.jobTitle.trim() || null,
        address_line: this.addressLine.trim(),
        postal_code: this.postalCode.trim(),
        city: this.city.trim(),
        country: this.country.trim() || 'FR',
        salary_cents: cents,
        contract_type: (this.contractType || null) as ContractType | null,
        hired_on: this.hiredOn || null,
        iban: this.iban.trim() || null,
      })
      .subscribe({
        next: (updated) => {
          this.dossier.set(updated);
          this.saving.set(false);
          this.toast.show(this.i18n.t('dossiers.saved'));
        },
        error: () => {
          this.saving.set(false);
          this.toast.show(this.i18n.t('dossiers.saveFail'));
        },
      });
  }

  resetPassword(): void {
    const d = this.dossier();
    if (!d || this.resetting()) return;
    this.resetting.set(true);
    this.usersApi.resetPassword(d.id).subscribe({
      next: (res) => {
        this.resetting.set(false);
        this.tempPassword.set(res.temporary_password);
        this.toast.show(this.i18n.t('dossiers.tempGenerated'));
      },
      error: () => {
        this.resetting.set(false);
        this.toast.show(this.i18n.t('dossiers.resetFail'));
      },
    });
  }

  unlockSignature(): void {
    const d = this.dossier();
    if (!d || this.unlocking()) return;
    this.unlocking.set(true);
    this.profiles.unlockSignature(d.id).subscribe({
      next: (updated) => {
        this.dossier.set(updated);
        this.unlocking.set(false);
        this.toast.show(this.i18n.t('dossiers.unlocked'));
      },
      error: () => {
        this.unlocking.set(false);
        this.toast.show(this.i18n.t('dossiers.unlockFail'));
      },
    });
  }
}
