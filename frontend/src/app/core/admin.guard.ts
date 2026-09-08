import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

/** Restricts a route to admins; sends everyone else back to the dashboard. */
export const adminGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.user()?.role === 'admin' ? true : router.createUrlTree(['/dashboard']);
};
