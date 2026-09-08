# Role-based work home (UI)

Daily users (employee, manager, RH) get a command dashboard: real numbers, one next action per widget, no fake data.

## Home by role

Everyone keeps the same shell. The dashboard layout changes with the signed-in role.

**Employee**

- Hero: remaining leave days + next confirmed leave (or CTA to request).
- Mes demandes: last 3 leaves with Manager → RH step chips.
- Documents: ready to download vs still with RH.
- Équipe aujourd’hui: real `/leave/schedule` for today.
- Quick actions: Nouvelle demande, Demander un document.

**Manager** (plus employee widgets if they take leave)

- File d’attente: `pending` leaves for their teams, Approuver / Refuser on the card.
- Cette semaine: who is out, from the schedule API.
- Sidebar badge on Validation des congés.

**RH / Admin**

- À confirmer: `pending_hr` leaves with confirm/refuse.
- Documents à rédiger: inbox count + 3 latest.
- Vue entreprise: who is out today.
- Sidebar badges on Validation and Documents RH.

## Visual system

Keep Alizé purple (`#460CAD`). Tighten, do not rebrand.

- 8px spacing, ~1280px content width, 12-column widget grid.
- Display type only on greeting and login headline; UI is a sharp sans.
- Widget anatomy: number, one-line context, one action. Color is for status only.
- Skeleton loaders. Empty states with a CTA.
- Tables: denser rows, hover, real action buttons.

## Shell and other pages

- Remove decorative search until it actually searches.
- Notification bell stays.
- Congés: two-step tracker on each row.
- Validation: Manager vs RH queues visually split; in-row approve/refuse.
- Équipe: member strip uses real schedule for today; calendar stays.
- Documents / Documents RH: status boards (À traiter / Prêt) instead of a naked table.
- Login: demo accounts as clickable chips.

## Data rules

Use existing APIs only: leave balance/requests/team, schedule, documents, teams/mine, notifications.

Remove: `presence(id)` fake team status, hardcoded 15 août holiday, fake search.

Widget approve/reject uses the same `LeaveService` methods as Validation, then refreshes. Failures use the existing toast.

## Out of scope

Drag-and-drop widgets, chart library, global search, public-holiday API, new backend endpoints.
