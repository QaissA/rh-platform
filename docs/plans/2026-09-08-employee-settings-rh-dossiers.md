# Employee settings and RH dossiers Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let employees edit address and password and request a job title; let RH/admin confirm that title and maintain a confidential dossier (salary, contract, start date, IBAN).

**Architecture:** All fields live on `users` in auth-service. Public JSON (`user_json`, `/auth/me`, `/auth/profile`, directory) never includes confidential columns. RH/admin use `dossier_json` on `GET/PATCH /auth/users/:id`. Job-title requests are `pending_job_title` plus accept/reject endpoints that notify via existing `Notification` + mailer. Frontend: Paramètres for everyone; Dossiers for RH/admin. Utilisateurs stays admin-only.

**Tech Stack:** Rails 8 auth-service, Angular 20, existing JWT gateway, existing notifications (`KINDS` whitelist).

**Do not commit** unless the user asks. Rebuild auth-service Docker image after backend changes (`docker compose up -d --build auth-service` from `backend/`). Verify with `npx ng build` and curl + browser walkthrough.

---

### Task 1: Migration and model

**Files:**
- Create: `backend/auth-service/db/migrate/20260908000003_add_profile_to_users.rb`
- Modify: `backend/auth-service/app/models/user.rb`
- Modify: `backend/auth-service/app/models/notification.rb` (`KINDS`)

**Columns:** `job_title`, `pending_job_title` (strings); `address_line`, `postal_code`, `city`, `country` (strings, country default `FR`); `salary_cents` (integer, nullable); `contract_type` (string, nullable); `hired_on` (date); `iban` (string).

**Validations:** `contract_type` inclusion in `%w[cdi cdd stage alternance other]` allow nil; `salary_cents` >= 0 allow nil; IBAN optional, strip spaces, max 34 chars.

**Notification kinds:** add `job_title_approved`, `job_title_rejected`.

---

### Task 2: JSON helpers and profile API

**Files:**
- Modify: `backend/auth-service/app/controllers/application_controller.rb`
- Create: `backend/auth-service/app/controllers/profiles_controller.rb`
- Modify: `backend/auth-service/config/routes.rb`

`profile_json(user)` = `user_json` + job_title, pending_job_title, address fields. Never salary/iban/contract/hired_on.

`dossier_json(user)` = `profile_json` + salary_cents, contract_type, hired_on, iban.

`GET /profile` and `PATCH /profile` (JWT). PATCH permits: `address_line`, `postal_code`, `city`, `country`, `pending_job_title`. Blank `pending_job_title` means cancel request. Cannot set `job_title` or confidential fields here.

Gateway already proxies `/auth/*` so frontend calls `/auth/profile`.

---

### Task 3: RH dossier API + job title accept/reject + reset password for RH

**Files:**
- Modify: `backend/auth-service/app/controllers/users_controller.rb`
- Modify: `backend/auth-service/app/controllers/internal_notifications_controller.rb` only if kinds are validated there (they live on the model)

- `index` stays admin-or-RH; add `job_title` to directory via `user_json` (safe).
- `show` (new): admin-or-RH, returns `dossier_json`.
- `update`: change `require_admin!` except index so **update, show, reset_password, accept/reject job title** are `require_admin_or_rh!`. Keep `create` and `destroy` admin-only.
- Update may set address, names, job_title (clears pending_job_title), salary_cents, contract_type, hired_on, iban. App `role` / team / org fields stay **admin-only** even on this action (if RH sends `role`, ignore or 403).
- `POST users/:id/job-title/accept` — if pending present, copy to job_title, clear pending, notify `job_title_approved`.
- `POST users/:id/job-title/reject` — clear pending, notify `job_title_rejected` (optional `comment`).
- Notifications: same `Notification.create!` + `NotificationMailer` pattern as `InternalNotificationsController`, or extract a one-liner service. Kind + title + body + link `/parametres`.
- `reset_password` allowed for RH.

---

### Task 4: Seeds and swagger/README

**Files:**
- Modify: `backend/auth-service/db/seeds.rb` — Emma address + job_title “Développeuse”; optional pending on another employee; RH dossier sample salary for Emma.
- Modify: `backend/api-gateway/swagger/v1/swagger.yaml`
- Modify: `backend/README.md` — `/auth/profile`, dossiers routes.

Existing DB: `db:prepare` on container start runs the new migration; re-seed only if you exec `db:seed` (optional).

---

### Task 5: Frontend models + profile service

**Files:**
- Modify: `frontend/src/app/core/models.ts` — `UserProfile`, `UserDossier`, contract types.
- Create: `frontend/src/app/core/profile.service.ts` — get/patch profile, get/patch dossier, accept/reject job title.
- Modify: `frontend/src/app/core/user-admin.service.ts` — `show(id)`, allow RH callers; keep create/destroy admin UI-only.
- Modify: `frontend/src/app/core/auth.service.ts` — after profile patch, merge public fields into stored user if needed.

---

### Task 6: Paramètres page

**Files:**
- Create: `frontend/src/app/features/settings/settings.ts` + `settings.html`
- Modify: `frontend/src/app/app.routes.ts` — `path: 'parametres'`
- Modify: `frontend/src/app/layout/shell/shell.ts` + `shell.html` — nav item Paramètres for everyone; title map.

Three cards: poste (current + pending + request), adresse form, mot de passe form (reuse AuthService.changePassword). Toasts on success. Empty job title: “Non renseigné”.

---

### Task 7: Dossiers pages

**Files:**
- Create: `frontend/src/app/features/dossiers/dossiers.ts` + html (list, pending banner, link to detail)
- Create: `frontend/src/app/features/dossiers/dossier-edit.ts` + html (form: names, address, job title, salary as euros input converted to cents, contract select, hired_on, iban; reset password button)
- Modify: routes with `rhGuard`
- Modify: shell — “Dossiers” under Espace for `isRh()`, next to Documents RH

Salary input: display euros (salary_cents/100), save `Math.round(euros * 100)`. Never show salary on list view; list shows name, job_title, pending badge only.

---

### Task 8: Verify

1. Rebuild `auth-service` so the migration runs.
2. `npx ng build` in `frontend/`.
3. Employee: open Paramètres, save address, request job title, change password (optional).
4. Confirm `/auth/profile` and `/auth/me` JSON have no `salary_cents` / `iban`.
5. RH: Dossiers list shows pending; accept; employee bell + job_title updated.
6. RH: set salary on Emma; employee settings still does not show it.
7. Admin Utilisateurs still creates users / changes app role.
8. RH cannot PATCH `role` on a user.
