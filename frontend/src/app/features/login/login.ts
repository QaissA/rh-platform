import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-login',
  imports: [FormsModule],
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  private auth = inject(AuthService);
  private router = inject(Router);

  email = 'employee@rh.local';
  password = 'password';
  loading = signal(false);
  error = signal<string | null>(null);

  fillDemo(email: string): void {
    this.email = email;
    this.password = 'password';
  }

  submit(): void {
    if (this.loading()) return;
    this.loading.set(true);
    this.error.set(null);
    this.auth.login(this.email, this.password).subscribe({
      next: () =>
        this.router.navigateByUrl(
          this.auth.mustChangePassword() ? '/change-password' : '/dashboard',
        ),
      error: (err) => {
        this.loading.set(false);
        this.error.set(
          err?.status === 0
            ? "Impossible de joindre le serveur. La passerelle est-elle démarrée ?"
            : 'E-mail ou mot de passe incorrect.',
        );
      },
    });
  }
}
