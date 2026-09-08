# Employee settings and RH dossiers

Employee self-service for address, password, and a job title that RH must confirm. RH/admin keep a confidential people file (salary, contract, start date, IBAN). App permission (employé / manager / RH / admin) stays admin-only.

## Employee — Paramètres

Sidebar link for every signed-in user.

- **Poste:** current `job_title`. Employee submits `pending_job_title`. Until RH acts, the UI shows “En attente de la RH”.
- **Adresse:** line, postal code, city, country. Saves immediately.
- **Mot de passe:** existing `PATCH /auth/password` (current + new, min 8).

Name stays RH/admin-editable. Employee cannot change app role.

Bell notification when RH accepts or refuses the job title.

## RH / admin — Dossiers

New screens `/dossiers` and `/dossiers/:id` (RH + admin). Pending job-title requests sit on top of the list (Accepter / Refuser).

The dossier can set identity, address, job title (applies immediately and clears pending), salary, contract type (`cdi` / `cdd` / `stage` / `alternance` / `other`), start date, IBAN. Password is a reset to a temporary password (same as admin today), never a read of the current secret.

**Utilisateurs** stays admin-only: create account, app permission, team.

## Data and APIs (auth-service)

Columns on `users`: `job_title`, `pending_job_title`, `address_line`, `postal_code`, `city`, `country`, `salary_cents`, `contract_type`, `hired_on`, `iban`.

- `GET`/`PATCH /auth/profile` — current user; PATCH address + pending job title only; **no** salary/IBAN/contract/hired_on in the JSON.
- `PATCH /auth/password` — unchanged.
- `GET /auth/users` — directory; add `job_title` (not confidential fields).
- `GET`/`PATCH /auth/users/:id` — RH + admin; confidential payload allowed.
- `POST /auth/users/:id/job-title/accept` and `.../reject` — RH + admin; notify employee.
- `POST /auth/users/:id/reset-password` — RH + admin.

`user_json` used for login/`/me`/directory must never include confidential columns. A separate `dossier_json` is only returned on RH/admin show/update.

## Out of scope

Employee-proposed app-role changes, payroll engine, file uploads, IBAN checksum beyond format length, manager viewing salary.
