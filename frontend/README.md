# Alizé — Frontend (Angular)

Single-page app for the enterprise HR ("RH") platform. Talks to the backend
**API gateway** on `http://localhost:3000`. French UI.

## Stack

- Angular 20 (standalone components, signals, new control flow `@if`/`@for`)
- Lazy-loaded feature routes, functional guard + HTTP interceptor
- Plain CSS design system (`src/styles.css`) — the "Alizé" tokens, light + dark themes

## Screens

| Route         | View                                                        |
|---------------|-------------------------------------------------------------|
| `/login`      | Login (JWT via `POST /auth/login`)                          |
| `/dashboard`  | KPIs, leave-balance meter, recent requests, team today      |
| `/conges`     | Leave balance + requests, new-request form                  |
| `/equipe`     | Team member cards + weekly presence strip                   |
| `/documents`  | Administrative document requests + new-request form         |
| `/utilisateurs` | **Admin only** — user & role management (list/create/change role/delete) |

## Run

Prerequisites: the backend must be running (`cd ../backend && docker compose up`)
so the gateway is reachable on `:3000`.

```bash
npm install
npm start          # ng serve — http://localhost:4200 (use --port 4300 if taken)
```

Log in with a seeded demo user (all `password`):
- **employee@rh.local** — normal user
- **manager@rh.local** — first validation of leave requests
- **rh@rh.local** — second validation; confirms the leave
- **admin@rh.local** — admin (sees the **Utilisateurs** admin screen)

## Build

```bash
npm run build      # outputs to dist/alize
```

## Architecture

```
src/app/
  core/                     # framework-agnostic app services
    api.ts                  # API_BASE_URL injection token (gateway origin)
    models.ts               # typed API contracts
    auth.service.ts         # login, JWT + user persistence (signals)
    auth.interceptor.ts     # attaches Bearer token to every request
    auth.guard.ts           # protects the shell routes
    theme.service.ts        # light/dark, follows OS unless overridden
    leave|team|document.service.ts
    toast.service.ts        # global confirmation toasts
    format.ts / labels.ts   # dates, initials, FR status labels
  layout/shell/             # sidebar + topbar + <router-outlet>
  features/                 # login, dashboard, conges, equipe, documents
```

### Auth flow

`AuthService.login()` posts to the gateway, stores the JWT + user in
`localStorage`, and exposes `isAuthenticated` / `user` as signals. The interceptor
adds `Authorization: Bearer <token>`; the gateway validates it and forwards the
user id to the microservices.

### Changing the API location

Override the `API_BASE_URL` injection token in `app.config.ts` (e.g. for a
deployed gateway). It defaults to `http://localhost:3000`.

## Notes / not yet wired to the backend

The backend skeleton has no presence service, so the **daily presence** chips and
the **weekly presence strip** use a deterministic client-side placeholder
(`presence()` in `core/format.ts`). The "prochain férié" tile is a fixed calendar
value. Everything else — login, balance, leave requests (list + create), team
members, documents (list + create) — is live data from the gateway.

## Design source

The approved visual maquette lives in `design/maquette.html` (also published as an
Artifact). The Angular components reproduce it with the same design tokens.
