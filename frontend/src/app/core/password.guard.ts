import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from './auth.service';

/**
 * Forces admin-created accounts through the change-password screen before they
 * can reach any protected page. Applied to the authenticated shell.
 */
export const passwordChangeGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.mustChangePassword() ? router.createUrlTree(['/change-password']) : true;
};

/**
 * Guards the change-password screen itself: only reachable while a forced
 * change is pending; otherwise send the user back to the dashboard.
 */
export const forcedPasswordGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.mustChangePassword() ? true : router.createUrlTree(['/dashboard']);
};
