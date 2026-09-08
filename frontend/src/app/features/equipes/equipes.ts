import { Component, computed, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TeamAdminService } from '../../core/team-admin.service';
import { ProjectAdminService } from '../../core/project-admin.service';
import { ToastService } from '../../core/toast.service';
import { I18nService } from '../../core/i18n.service';
import { TranslatePipe } from '../../core/translate.pipe';
import { Project, TeamSummary } from '../../core/models';

@Component({
  selector: 'app-equipes',
  imports: [FormsModule, TranslatePipe],
  templateUrl: './equipes.html',
})
export class Equipes {
  private api = inject(TeamAdminService);
  private projectApi = inject(ProjectAdminService);
  private toast = inject(ToastService);
  private i18n = inject(I18nService);

  protected loading = signal(true);
  protected submitting = signal(false);
  protected panelOpen = signal(false);
  protected teams = signal<TeamSummary[]>([]);
  protected projects = signal<Project[]>([]);
  protected busyId = signal<number | null>(null);
  protected confirmId = signal<number | null>(null);
  protected editingId = signal<number | null>(null);
  protected editName = '';

  protected name = '';
  protected projectId = '';

  protected totalMembers = computed(() =>
    this.teams().reduce((acc, t) => acc + (t.member_count ?? 0), 0),
  );
  protected freeProjects = computed(() => {
    const taken = new Set(this.teams().map((t) => t.project_id).filter((id): id is number => id != null));
    return this.projects().filter((p) => !taken.has(p.id));
  });

  protected nameValid = (): boolean => this.name.trim().length > 0;
  protected projectOptions = (team: TeamSummary): Project[] => {
    const free = this.freeProjects();
    const current = this.projects().find((p) => p.id === team.project_id);
    return current && !free.some((p) => p.id === current.id) ? [current, ...free] : free;
  };

  constructor() {
    this.reload();
    this.loadProjects();
  }

  togglePanel(): void {
    this.panelOpen.update((v) => !v);
  }

  submit(): void {
    if (this.submitting() || !this.nameValid()) return;
    this.submitting.set(true);
    this.api.create({ name: this.name.trim(), project_id: this.toId(this.projectId) }).subscribe({
      next: () => {
        this.submitting.set(false);
        this.panelOpen.set(false);
        this.name = '';
        this.projectId = '';
        this.toast.show(this.i18n.t('teamsAdmin.created'));
        this.reload();
      },
      error: (err) => {
        this.submitting.set(false);
        this.toast.show(this.errorText(err, 'teamsAdmin.createFail'));
      },
    });
  }

  changeProject(team: TeamSummary, value: string): void {
    const project_id = this.toId(value);
    if (project_id === (team.project_id ?? null)) return;
    this.busyId.set(team.id);
    this.api.update(team.id, { project_id }).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.replace(updated);
        this.toast.show(this.i18n.t('teamsAdmin.projectUpdated', { name: updated.name }));
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'teamsAdmin.assignFail'));
        this.reload();
      },
    });
  }

  startRename(team: TeamSummary): void {
    this.editName = team.name;
    this.editingId.set(team.id);
  }
  cancelRename(): void {
    this.editingId.set(null);
  }
  saveRename(team: TeamSummary): void {
    const name = this.editName.trim();
    if (!name || name === team.name) {
      this.editingId.set(null);
      return;
    }
    this.busyId.set(team.id);
    this.api.update(team.id, { name }).subscribe({
      next: (updated) => {
        this.busyId.set(null);
        this.editingId.set(null);
        this.replace(updated);
        this.toast.show(this.i18n.t('teamsAdmin.renamed'));
      },
      error: (err) => {
        this.busyId.set(null);
        this.toast.show(this.errorText(err, 'teamsAdmin.renameFail'));
      },
    });
  }

  askDelete(id: number): void {
    this.confirmId.set(id);
  }
  cancelDelete(): void {
    this.confirmId.set(null);
  }
  confirmDelete(team: TeamSummary): void {
    this.busyId.set(team.id);
    this.api.remove(team.id).subscribe({
      next: () => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.teams.update((list) => list.filter((t) => t.id !== team.id));
        this.toast.show(this.i18n.t('teamsAdmin.deleted', { name: team.name }));
      },
      error: (err) => {
        this.busyId.set(null);
        this.confirmId.set(null);
        this.toast.show(this.errorText(err, 'teamsAdmin.deleteFail'));
      },
    });
  }

  private reload(): void {
    this.loading.set(true);
    this.api.list().subscribe({
      next: (t) => {
        this.teams.set(t);
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  private loadProjects(): void {
    this.projectApi.list().subscribe((p) => this.projects.set(p));
  }

  private replace(updated: TeamSummary): void {
    this.teams.update((list) => list.map((t) => (t.id === updated.id ? updated : t)));
  }

  private toId(value: string): number | null {
    return value ? Number(value) : null;
  }

  private errorText(err: unknown, fallbackKey: string): string {
    const e = err as { error?: { error?: string; errors?: string[] } };
    return e?.error?.error || e?.error?.errors?.join(', ') || this.i18n.t(fallbackKey);
  }
}
