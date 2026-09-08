import { Component, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ToastService } from './core/toast.service';
import { I18nService } from './core/i18n.service';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {
  protected toast = inject(ToastService);
  constructor() {
    inject(I18nService);
  }
}
