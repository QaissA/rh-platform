import { Component, inject } from '@angular/core';
import { I18nService, Lang } from '../core/i18n.service';
import { TranslatePipe } from '../core/translate.pipe';

@Component({
  selector: 'app-lang-switcher',
  imports: [TranslatePipe],
  template: `
    <div class="langswitch" role="group" [attr.aria-label]="'lang.label' | t">
      @for (opt of langs; track opt) {
        <button
          type="button"
          class="langswitch__btn"
          [class.is-on]="i18n.lang() === opt"
          (click)="i18n.setLang(opt)"
        >{{ opt.toUpperCase() }}</button>
      }
    </div>
  `,
})
export class LangSwitcher {
  protected i18n = inject(I18nService);
  protected langs: Lang[] = ['fr', 'en', 'ar'];
}
