import { InjectionToken } from '@angular/core';

/** Base URL of the API gateway. Override in environment wiring if needed. */
export const API_BASE_URL = new InjectionToken<string>('API_BASE_URL', {
  providedIn: 'root',
  factory: () => 'http://localhost:3000',
});
