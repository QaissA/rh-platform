import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

/** Restricts a route to managers, RH, and admins; others go back to the dashboard. */
export const managerGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const role = auth.user()?.role;
  return role === 'manager' || role === 'rh' || role === 'admin'
    ? true
    : router.createUrlTree(['/dashboard']);
};
