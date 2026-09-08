import { Routes } from '@angular/router';
import { authGuard } from './core/auth.guard';
import { adminGuard } from './core/admin.guard';
import { managerGuard } from './core/manager.guard';
import { rhGuard } from './core/rh.guard';
import { forcedPasswordGuard, passwordChangeGuard } from './core/password.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () => import('./features/login/login').then((m) => m.Login),
  },
  {
    path: 'change-password',
    canActivate: [authGuard, forcedPasswordGuard],
    loadComponent: () =>
      import('./features/change-password/change-password').then((m) => m.ChangePassword),
  },
  {
    path: '',
    loadComponent: () => import('./layout/shell/shell').then((m) => m.Shell),
    canActivate: [authGuard, passwordChangeGuard],
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () => import('./features/dashboard/dashboard').then((m) => m.Dashboard),
      },
      {
        path: 'conges',
        loadComponent: () => import('./features/conges/conges').then((m) => m.Conges),
      },
      {
        path: 'equipe',
        loadComponent: () => import('./features/equipe/equipe').then((m) => m.Equipe),
      },
      {
        path: 'validation-conges',
        canActivate: [managerGuard],
        loadComponent: () =>
          import('./features/validation-conges/validation-conges').then((m) => m.ValidationConges),
      },
      {
        path: 'documents',
        loadComponent: () => import('./features/documents/documents').then((m) => m.Documents),
      },
      {
        path: 'documents/:id',
        loadComponent: () =>
          import('./features/documents/document-view').then((m) => m.DocumentView),
      },
      {
        path: 'documents-rh',
        canActivate: [rhGuard],
        loadComponent: () =>
          import('./features/documents-rh/documents-rh').then((m) => m.DocumentsRh),
      },
      {
        path: 'documents-rh/:id',
        canActivate: [rhGuard],
        loadComponent: () =>
          import('./features/documents-rh/documents-rh-edit').then((m) => m.DocumentsRhEdit),
      },
      {
        path: 'dossiers',
        canActivate: [rhGuard],
        loadComponent: () => import('./features/dossiers/dossiers').then((m) => m.Dossiers),
      },
      {
        path: 'dossiers/:id',
        canActivate: [rhGuard],
        loadComponent: () =>
          import('./features/dossiers/dossier-edit').then((m) => m.DossierEdit),
      },
      {
        path: 'parametres',
        loadComponent: () => import('./features/settings/settings').then((m) => m.Settings),
      },
      {
        path: 'equipes',
        canActivate: [adminGuard],
        loadComponent: () => import('./features/equipes/equipes').then((m) => m.Equipes),
      },
      {
        path: 'business-units',
        canActivate: [adminGuard],
        loadComponent: () =>
          import('./features/business-units/business-units').then((m) => m.BusinessUnits),
      },
      {
        path: 'projets',
        canActivate: [adminGuard],
        loadComponent: () => import('./features/projets/projets').then((m) => m.Projets),
      },
      {
        path: 'utilisateurs',
        canActivate: [adminGuard],
        loadComponent: () => import('./features/users/users').then((m) => m.Users),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
