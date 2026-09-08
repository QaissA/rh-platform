import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { FullCalendarModule } from '@fullcalendar/angular';
import { CalendarOptions, DatesSetArg, EventInput } from '@fullcalendar/core';
import dayGridPlugin from '@fullcalendar/daygrid';
import interactionPlugin, { DateClickArg } from '@fullcalendar/interaction';
import frLocale from '@fullcalendar/core/locales/fr';
import { TeamService } from '../../core/team.service';
import { ScheduleService } from '../../core/schedule.service';
import { AuthService } from '../../core/auth.service';
import { ToastService } from '../../core/toast.service';
import { DeclarableStatus, PresenceStatus, ScheduleEntry, TeamMember } from '../../core/models';
import { avatarClass, fullName, initials, jobTitleOf } from '../../core/format';
import { PRESENCE_CHIP, PRESENCE_LABEL } from '../../core/labels';

interface MemberCard {
  id: number;
  name: string;
  jobTitle: string | null;
  role: string;
  email: string;
  initials: string;
  av: string;
  status: PresenceStatus;
  chip: string;
  statusLabel: string;
  isMe: boolean;
}

// Only remote & holiday are drawn on the calendar; on-site is the implicit
// default (a day with no chip = everyone is on site). Colours reference the
// design-system tokens so the calendar follows the light/dark theme.
const EVENT_STYLE: Record<'remote' | 'holiday', { bg: string; fg: string }> = {
  remote: { bg: 'var(--info-tint)', fg: 'var(--info)' },
  holiday: { bg: 'var(--warn-tint)', fg: 'var(--warn)' },
};

@Component({
  selector: 'app-equipe',
  imports: [FullCalendarModule, FormsModule],
  templateUrl: './equipe.html',
})
export class Equipe {
  private team = inject(TeamService);
  private schedule = inject(ScheduleService);
  private auth = inject(AuthService);
  private toast = inject(ToastService);

  protected loading = signal(true);
  protected teamName = signal<string>('');
  protected members = signal<MemberCard[]>([]);
  protected hasTeam = signal(true);

  // Declaration panel (self-service work location).
  protected panelOpen = signal(false);
  protected submitting = signal(false);
  protected declStart = signal('');
  protected declEnd = signal('');
  protected declStatus = signal<DeclarableStatus>('remote');

  private meId = 0;
  private roster: TeamMember[] = [];
  private shortNames = new Map<number, string>();
  private stateMap = new Map<string, PresenceStatus>(); // `${userId}|${date}` -> status
  // Monotonic token so a slow response for an old month can't overwrite a newer one.
  private scheduleReq = 0;

  protected calendarOptions = signal<CalendarOptions>({
    plugins: [dayGridPlugin, interactionPlugin],
    initialView: 'dayGridMonth',
    locale: frLocale,
    firstDay: 1,
    height: 'auto',
    fixedWeekCount: false,
    displayEventTime: false,
    eventDisplay: 'block',
    dayMaxEvents: 4,
    headerToolbar: { left: 'prev,next today', center: 'title', right: '' },
    datesSet: (arg) => this.onDatesSet(arg),
    dateClick: (arg) => this.onDateClick(arg),
    events: [],
  });

  constructor() {
    this.team.getMine().subscribe({
      next: (res) => {
        this.teamName.set(res.team?.name ?? 'Sans équipe');
        this.hasTeam.set(!!res.team);
        const me = this.auth.user();
        this.meId = me?.id ?? 0;
        const self: TeamMember | null = me
          ? {
              id: me.id,
              email: me.email,
              first_name: me.first_name ?? null,
              last_name: me.last_name ?? null,
              role: me.role,
              job_title: me.job_title ?? null,
            }
          : null;
        this.roster = self ? [self, ...(res.members ?? [])] : (res.members ?? []);
        this.roster.forEach((m) => this.shortNames.set(m.id, this.toShort(m)));
        this.refreshCards();
        this.rebuildEvents();
        this.loading.set(false);
      },
      error: () => this.loading.set(false),
    });
  }

  // ---- calendar data ---------------------------------------------------------

  private onDatesSet(arg: DatesSetArg): void {
    // arg.endStr is exclusive (day after the last visible cell); the backend
    // treats `end` as inclusive, so this simply covers the whole grid.
    const token = ++this.scheduleReq;
    this.schedule.getSchedule(arg.startStr.slice(0, 10), arg.endStr.slice(0, 10)).subscribe({
      next: (res) => {
        if (token === this.scheduleReq) this.ingest(res.entries);
      },
    });
  }

  private ingest(entries: ScheduleEntry[]): void {
    this.stateMap.clear();
    for (const e of entries) this.stateMap.set(`${e.user_id}|${e.date}`, e.status);
    this.refreshCards();
    this.rebuildEvents();
  }

  private rebuildEvents(): void {
    const events: EventInput[] = [];
    for (const [key, status] of this.stateMap) {
      if (status === 'on_site') continue;
      const [userId, date] = key.split('|');
      const style = EVENT_STYLE[status];
      events.push({
        title: this.shortNames.get(Number(userId)) ?? 'Membre',
        start: date,
        allDay: true,
        backgroundColor: style.bg,
        borderColor: style.fg,
        textColor: style.fg,
      });
    }
    this.calendarOptions.update((o) => ({ ...o, events }));
  }

  private refreshCards(): void {
    const today = this.todayIso();
    this.members.set(
      this.roster.map((m) => {
        const status = this.stateMap.get(`${m.id}|${today}`) ?? 'on_site';
        return {
          id: m.id,
          name: fullName(m),
          jobTitle: jobTitleOf(m),
          role: m.role,
          email: m.email,
          initials: initials(m),
          av: avatarClass(m.id),
          status,
          chip: PRESENCE_CHIP[status],
          statusLabel: PRESENCE_LABEL[status],
          isMe: m.id === this.meId,
        };
      }),
    );
  }

  // ---- declaration panel -----------------------------------------------------

  private onDateClick(arg: DateClickArg): void {
    this.declStart.set(arg.dateStr);
    this.declEnd.set(arg.dateStr);
    this.panelOpen.set(true);
  }

  togglePanel(): void {
    this.panelOpen.update((v) => !v);
  }

  submit(): void {
    const start = this.declStart();
    if (this.submitting() || !start) return;
    this.submitting.set(true);
    this.schedule
      .declarePresence({
        start_date: start,
        end_date: this.declEnd() || start,
        status: this.declStatus(),
      })
      .subscribe({
        next: () => {
          this.submitting.set(false);
          this.panelOpen.set(false);
          this.toast.show('Présence enregistrée');
          this.reloadCurrent();
        },
        error: () => {
          this.submitting.set(false);
          this.toast.show("Échec de l'enregistrement");
        },
      });
  }

  // Re-fetch the range currently shown so a new declaration appears at once.
  private reloadCurrent(): void {
    const today = this.todayIso();
    const first = today.slice(0, 8) + '01';
    const token = ++this.scheduleReq;
    this.schedule.getSchedule(first, this.endOfMonth(today)).subscribe((res) => {
      if (token === this.scheduleReq) this.ingest(res.entries);
    });
  }

  private todayIso(): string {
    const d = new Date();
    return `${d.getFullYear()}-${this.pad(d.getMonth() + 1)}-${this.pad(d.getDate())}`;
  }

  private endOfMonth(iso: string): string {
    const [y, m] = iso.split('-').map(Number);
    const last = new Date(y, m, 0).getDate();
    return `${y}-${this.pad(m)}-${this.pad(last)}`;
  }

  private pad(n: number): string {
    return String(n).padStart(2, '0');
  }

  private toShort(m: TeamMember): string {
    const parts = fullName(m).split(' ');
    return parts.length > 1 ? `${parts[0]} ${parts[1][0]}.` : parts[0];
  }
}
