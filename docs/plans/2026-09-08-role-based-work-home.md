# Role-based work home Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn Alizé’s generic dashboard and daily pages into a role-based work home with actionable widgets, real schedule data, and a tighter layout — without new APIs or a chart library.

**Architecture:** Keep the Angular 20 standalone app and global CSS tokens in `frontend/src/styles.css`. Rewrite `Dashboard` as a role-aware command screen. Extract small presentational pieces (step tracker, queue row, skeleton) as needed. Feature pages (Congés, Validation, Équipe, Documents) keep their routes and services; they only gain layout/status UI. Shell drops fake search and shows queue badges from the same leave/document queries.

**Tech Stack:** Angular 20, existing `LeaveService` / `ScheduleService` / `DocumentService` / `TeamService` / `ToastService`, CSS variables (no Tailwind, no chart lib).

**Verification:** `npx ng build` in `frontend/`. Walk employee, manager, and RH in the browser at http://localhost:4300. This repo has almost no frontend unit tests; do not add a test framework for CSS. Prefer browser evidence.

**Do not commit** unless the user explicitly asks.

---

### Task 1: Tokens, type, content width

**Files:**
- Modify: `frontend/src/index.html`
- Modify: `frontend/src/styles.css`
- Modify: `frontend/src/app/layout/shell/shell.html`
- Modify: `frontend/src/app/layout/shell/shell.ts`

**Step 1:** Load a UI sans (e.g. Source Sans 3) from Google Fonts in `index.html`. Keep one display face only for greeting/login headlines (e.g. Fraunces or keep a restrained serif). Set `--sans`, `--display`, `--maxw: 1280px`, `--space` 8px rhythm. Do not change `--brand: #460CAD`.

**Step 2:** Remove the decorative `.search` block from `shell.html`. Keep theme toggle and notification bell. Add optional count pills on Validation / Documents RH nav links (wire data in a later task; CSS class `.nav a .count` already exists).

**Step 3:** Verify `npx ng build` still succeeds.

---

### Task 2: Shared widget / list / skeleton styles

**Files:**
- Modify: `frontend/src/styles.css`

**Step 1:** Add:

- `.dash-grid` — 12-column CSS grid, 16px gap, widgets spanning 4/6/8/12.
- `.widget` — card with header, metric, context, footer action.
- `.queue` — person + dates + `StepTracker` + actions.
- `.stepper` — Manager → RH (pending / pending_hr / approved / rejected).
- `.skel` — pulse placeholders.
- `.board` — two or three status columns for documents.
- Denser table rows and `.btn` actions in tables (replace `.linkbtn` as the primary pattern on Validation).

**Step 2:** Keep dark-theme tokens working. No new colors except status already in the system.

---

### Task 3: Kill fake data helpers

**Files:**
- Modify: `frontend/src/app/core/format.ts`
- Modify: `frontend/src/app/features/dashboard/dashboard.ts`
- Modify: `frontend/src/app/features/dashboard/dashboard.html`

**Step 1:** Delete `presence()` and the `PRESENCE` array from `format.ts`. Grep to confirm no remaining callers.

**Step 2:** Remove the hardcoded “15 août / Assomption” KPI from the dashboard. Do not replace it with another fake holiday.

---

### Task 4: Dashboard data by role

**Files:**
- Modify: `frontend/src/app/features/dashboard/dashboard.ts`
- Modify: `frontend/src/app/features/dashboard/dashboard.html`

**Step 1:** Detect role from `AuthService.user()`:

- `employee` / `lead` → employee home
- `manager` → manager home (+ employee leave/docs widgets)
- `rh` / `admin` → RH home (+ employee widgets if useful; admin gets RH queues)

**Step 2:** Load in parallel (forkJoin / combineLatest):

- Always: `getBalance()`, `getRequests()`, `getRequests()` documents, `getMine()`, `getSchedule(today, today)` (and for manager/RH also week start–end).
- Manager: `getTeamRequests('pending')`
- RH/admin: `getTeamRequests('pending_hr')` + `getInbox()` (or inbox without filter, then count open)

**Step 3:** Map schedule entries + team members into a today list using `PRESENCE_LABEL` / `PRESENCE_CHIP`. Default missing entry to `on_site` (same convention as Équipe calendar).

**Step 4:** Loading = skeleton widgets. Error = toast + empty widgets, page still renders.

---

### Task 5: Employee widgets

**Files:**
- Modify: `frontend/src/app/features/dashboard/dashboard.html`
- Modify: `frontend/src/app/features/dashboard/dashboard.ts`

**Step 1:** Hero: `{days_remaining} jours` + next `approved` leave in the future, or “Aucune absence à venir” + button to `/conges`.

**Step 2:** Mes demandes: last 3 with stepper + link “Tout voir”.

**Step 3:** Documents: count ready vs not ready; list ready with link `/documents/:id`.

**Step 4:** Équipe aujourd’hui from real schedule.

**Step 5:** Quick actions: `/conges` and `/documents`.

Empty states must include the CTA, never a blank card.

---

### Task 6: Manager and RH queue widgets

**Files:**
- Modify: `frontend/src/app/features/dashboard/dashboard.ts`
- Modify: `frontend/src/app/features/dashboard/dashboard.html`
- Modify: `frontend/src/app/layout/shell/shell.ts`
- Modify: `frontend/src/app/layout/shell/shell.html`

**Step 1:** Manager widget “File d’attente”: pending team leaves. Resolve names via `teams/mine` members plus, if needed, the same name map Validation already uses. Actions call `LeaveService.approve` / `reject` then reload dashboard. Toast on success/fail.

**Step 2:** “Cette semaine”: members with `holiday` (or remote) on any day of the current week from schedule.

**Step 3:** RH widget “À confirmer”: `pending_hr` with confirm/refuse. “Documents à rédiger”: open inbox items, link `/documents-rh/:id`. “Vue entreprise”: today strip from schedule if available; if RH has no team schedule, show the pending_hr people out instead of a fake list.

**Step 4:** Sidebar badges: pending count on Validation; open document count on Documents RH. Load these in Shell (small extra GETs) or pass via a tiny `InboxBadgeService` so counts survive leaving the dashboard. Prefer a small service over duplicating HTTP in Shell.

---

### Task 7: Congés step tracker

**Files:**
- Modify: `frontend/src/app/features/conges/conges.html`
- Modify: `frontend/src/app/features/conges/conges.ts` (if needed)
- Modify: `frontend/src/styles.css` (reuse `.stepper`)

**Step 1:** On each request row, show Manager → RH states:

- `pending`: manager current, RH idle
- `pending_hr`: manager done, RH current
- `approved`: both done
- `rejected`: mark the step that refused (manager if still pending-era; if we cannot know, show Refusé on the chip only)

Keep the existing form and KPIs; restyle tiles to the widget pattern.

---

### Task 8: Validation and Documents boards

**Files:**
- Modify: `frontend/src/app/features/validation-conges/validation-conges.html`
- Modify: `frontend/src/app/features/validation-conges/validation-conges.ts`
- Modify: `frontend/src/app/features/documents/documents.html`
- Modify: `frontend/src/app/features/documents-rh/documents-rh.html`
- Modify: `frontend/src/app/features/equipe/equipe.html`
- Modify: `frontend/src/app/features/equipe/equipe.ts`

**Step 1:** Validation: visually split “En attente manager” vs “En attente RH” when filter is pending (two sections). Replace `.linkbtn` with `.btn.btn--sm`. Keep in-row approve/refuse and reject comment flow.

**Step 2:** Documents employee: board columns or grouped lists for En attente / Prêt.

**Step 3:** Documents RH: À traiter / Prêt (or Traitées) grouping; keep Rédiger button.

**Step 4:** Équipe member cards: today’s status from `getSchedule(today, today)`, not any leftover fake mapping.

---

### Task 9: Login demo chips

**Files:**
- Modify: `frontend/src/app/features/login/login.html`
- Modify: `frontend/src/app/features/login/login.ts`
- Modify: `frontend/src/app/features/login/login.css`

**Step 1:** Replace the single demo hint with three chips: Employé, Manager, RH filling `employee@rh.local`, `manager@rh.local`, `rh@rh.local` (password still `password`). One click fills the form; user still submits (or click can submit — filling is enough).

**Step 2:** Keep the split brand pane and pitch. Apply `--display` to the headline.

---

### Task 10: Browser verification

**Roles and passwords:** all `password`.

Walk at http://localhost:4300 (or 4200):

1. Employee: dashboard shows real balance, real schedule, no 15 août, no fake presence, no search box. Documents/leaves widgets match `/conges` and `/documents`.
2. Manager: queue shows pending leaves; approve from home updates Validation. Week strip matches Équipe calendar.
3. RH: pending_hr + document inbox on home; confirm leave and open a document to rédiger.
4. Dark theme still readable.
5. Empty states: a user with no team still gets a CTA, not a crash.
6. `npx ng build` exit 0.

If a widget would need a new backend field, omit the widget rather than invent data.
