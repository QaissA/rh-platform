import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ProjectAdminService } from '../../core/project-admin.service';
import { BusinessUnitAdminService } from '../../core/business-unit-admin.service';
import { UserAdminService } from '../../core/user-admin.service';
import { ToastService } from '../../core/toast.service';
import { BusinessUnit, Project, User } from '../../core/models';
import { fullName } from '../../core/format';

@Component({
  selector: 'app-projets',
  imports: [FormsModule],
  templateUrl: './projets.html',
})
export class Projets {
  private api = inject(ProjectAdminService);
  private buApi = inject(BusinessUnitAdminService);
  private userApi = inject(UserAdminService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected projects = signal<Project[]>([]);
  protected units = signal<BusinessUnit[]>([]);
  protected leads = signal<User[]>([]);
  protected busyId = signal<number | null>(null);
  protected confirmId = signal<number | null>(null);
  protected editingId = signal<number | null>(null);
  protected editName = '';
  protected filterBu = signal('');

  // create form
  protected name = '';
  protected businessUnitId = '';
  protected leadId = '';

  protected nameValid = (): boolean => this.name.trim().length > 0;
  protected leadName = (u: User) => fullName(u);

  constructor() {
    this.reload();
    this.loadOptions();
  }

  togglePanel(): void {
    this.panelOpen.update((v) => !v);
  }

  setFilter(value: string): void {
    this.filterBu.set(value);
    this.reload();
  }

  submit(): void {
    if (this.submitting() || !this.nameValid() || !this.businessUnitId) return;
    this.submitting.set(true);
    this.api
      .create({
        name: this.name.trim(),
        business_unit_id: Number(this.businessUnitId),
        lead_id: this.toId(this.leadId),
      })
      .subscribe({
        next: () => {
          this.submitting.set(false);
          this.panelOpen.set(false);
          this.name = '';
          this.leadId = '';
          this.toast.show('Projet créé');
          this.reload();
        },
        error: (err) => {
          this.submitting.set(false);
          this.toast.show(this.errorText(err, 'Échec de la création du projet'));
        },
      });
  }

  changeLead(project: Project, value: string): void {
    const lead_id = this.toId(value);
    if (lead_id === (project.lead_id ?? null)) return;
    this.busyId.set(project.id);
    this.api.update(project.id, { lead_id }).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.replace(updated);
        this.toast.show(`Chef·fe de projet mis·e à jour pour ${updated.name}`);
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'Assignation refusée'));
        this.reload();
      },
    });
  }

  startRename(project: Project): void {
    this.editName = project.name;
    this.editingId.set(project.id);
  }
  cancelRename(): void {
    this.editingId.set(null);
  }
  saveRename(project: Project): void {
    const name = this.editName.trim();
    if (!name || name === project.name) {
      this.editingId.set(null);
      return;
    }
    this.busyId.set(project.id);
    this.api.update(project.id, { name }).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.editingId.set(null);
        this.replace(updated);
        this.toast.show('Projet renommé');
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
  confirmDelete(project: Project): void {
    this.busyId.set(project.id);
    this.api.remove(project.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.projects.update((list) => list.filter((p) => p.id !== project.id));
        this.toast.show(`Projet « ${project.name} » supprimé`);
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
    const bu = this.filterBu() ? Number(this.filterBu()) : undefined;
    this.api.list(bu).subscribe({
      next: (p) => {
        this.projects.set(p);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  private loadOptions(): void {
    this.buApi.list().subscribe((b) => this.units.set(b));
    this.userApi.list().subscribe((users) => this.leads.set(users.filter((u) => u.role === 'lead' || u.role === 'admin')));
  }

  private replace(updated: Project): void {
    this.projects.update((list) => list.map((p) => (p.id === updated.id ? updated : p)));
  }

  private toId(value: string): number | null {
    return value ? Number(value) : null;
  }

  private errorText(err: unknown, fallback: string): string {
    const e = err as { error?: { error?: string; errors?: string[] } };
    return e?.error?.error || e?.error?.errors?.join(', ') || fallback;
  }
}
