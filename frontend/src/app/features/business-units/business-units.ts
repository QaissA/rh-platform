import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { BusinessUnitAdminService } from '../../core/business-unit-admin.service';
import { UserAdminService } from '../../core/user-admin.service';
import { ToastService } from '../../core/toast.service';
import { BusinessUnit, User } from '../../core/models';
import { fullName } from '../../core/format';

@Component({
  selector: 'app-business-units',
  imports: [FormsModule],
  templateUrl: './business-units.html',
})
export class BusinessUnits {
  private api = inject(BusinessUnitAdminService);
  private userApi = inject(UserAdminService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected units = signal<BusinessUnit[]>([]);
  protected managers = signal<User[]>([]);
  protected busyId = signal<number | null>(null);
  protected confirmId = signal<number | null>(null);
  protected editingId = signal<number | null>(null);
  protected editName = '';

  // create form
  protected name = '';
  protected managerId = '';

  protected totalProjects = computed(() =>
    this.units().reduce((acc, b) => acc + (b.project_count ?? 0), 0),
  );

  protected nameValid = (): boolean => this.name.trim().length > 0;
  protected managerName = (u: User) => fullName(u);

  constructor() {
    this.reload();
    this.loadManagers();
  }

  togglePanel(): void {
    this.panelOpen.update((v) => !v);
  }

  submit(): void {
    if (this.submitting() || !this.nameValid()) return;
    this.submitting.set(true);
    this.api.create({ name: this.name.trim(), manager_id: this.toId(this.managerId) }).subscribe({
      next: () => {
        this.submitting.set(false);
        this.panelOpen.set(false);
        this.name = '';
        this.managerId = '';
        this.toast.show('Business unit créée');
        this.reload();
      },
      error: (err) => {
        this.submitting.set(false);
        this.toast.show(this.errorText(err, 'Échec de la création'));
      },
    });
  }

  changeManager(unit: BusinessUnit, value: string): void {
    const manager_id = this.toId(value);
    if (manager_id === (unit.manager_id ?? null)) return;
    this.busyId.set(unit.id);
    this.api.update(unit.id, { manager_id }).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.replace(updated);
        this.toast.show(`Manager mis à jour pour ${updated.name}`);
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'Assignation refusée'));
        this.reload();
      },
    });
  }

  startRename(unit: BusinessUnit): void {
    this.editName = unit.name;
    this.editingId.set(unit.id);
  }
  cancelRename(): void {
    this.editingId.set(null);
  }
  saveRename(unit: BusinessUnit): void {
    const name = this.editName.trim();
    if (!name || name === unit.name) {
      this.editingId.set(null);
      return;
    }
    this.busyId.set(unit.id);
    this.api.update(unit.id, { name }).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.editingId.set(null);
        this.replace(updated);
        this.toast.show('Business unit renommée');
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'Renommage refusé'));
      },
    });
  }

  askDelete(id: number): void {
    this.confirmId.set(id);
  }
  cancelDelete(): void {
    this.confirmId.set(null);
  }
  confirmDelete(unit: BusinessUnit): void {
    this.busyId.set(unit.id);
    this.api.remove(unit.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.units.update((list) => list.filter((b) => b.id !== unit.id));
        this.toast.show(`Business unit « ${unit.name} » supprimée`);
      },
      error: (err) => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.toast.show(this.errorText(err, 'Suppression refusée'));
      },
    });
  }

  private reload(): void {
    this.loading.set(true);
    this.api.list().subscribe({
      next: (b) => {
        this.units.set(b);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  private loadManagers(): void {
    this.userApi.list().subscribe((users) =>
      this.managers.set(users.filter((u) => u.role === 'manager' || u.role === 'admin')),
    );
  }

  private replace(updated: BusinessUnit): void {
    this.units.update((list) => list.map((b) => (b.id === updated.id ? updated : b)));
  }

  private toId(value: string): number | null {
    return value ? Number(value) : null;
  }

  private errorText(err: unknown, fallback: string): string {
    const e = err as { error?: { error?: string; errors?: string[] } };
    return e?.error?.error || e?.error?.errors?.join(', ') || fallback;
  }
}
