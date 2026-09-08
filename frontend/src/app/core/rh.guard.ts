import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

/** Restricts a route to RH and admins. */
export const rhGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  const role = auth.user()?.role;
  return role === 'rh' || role === 'admin' ? true : router.createUrlTree(['/dashboard']);
};
