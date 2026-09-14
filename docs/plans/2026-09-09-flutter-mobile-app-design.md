# Alizé Flutter mobile app (design)

A Flutter client for the existing RH platform. Same product as the Angular app in `frontend/`: login through the API gateway, role-based work, leave, team, chat, documents, settings, RH dossiers, and admin org CRUD. Extra mobile-only product features are out of scope for this design; the layering is there so they can land later.

## Product

Alizé is an enterprise HR app. Clients talk only to the **api-gateway** (`:3000`). JWT on every request. Roles: `employee`, `lead`, `manager`, `rh`, `admin`.

**v1 = full web parity**, including admin screens. New product features wait.

| Angular route | Mobile destination | Who |
|---|---|---|
| `/login` | Login | public |
| `/change-password` | Forced password change | signed-in + `must_change_password` |
| `/dashboard` | Home | all |
| `/conges` | Leave | all |
| `/equipe` | Team | all |
| `/messages` | Messages | all |
| `/validation-conges` | Leave review | manager, rh, admin |
| `/documents`, `/documents/:id` | Documents | all |
| `/documents-rh`, `/documents-rh/:id` | RH documents | rh, admin |
| `/dossiers`, `/dossiers/:id` | Dossiers | rh, admin |
| `/parametres` | Settings | all |
| `/business-units`, `/projets`, `/equipes`, `/utilisateurs` | Admin org | admin |

Demo accounts (password `password`): `employee@rh.local`, `manager@rh.local`, `rh@rh.local`, `admin@rh.local`.

## Architecture

Feature-first clean architecture in `mobile/` at the repo root. Each feature owns `domain` / `data` / `presentation`. Shared kernel under `lib/core`.

```
mobile/lib/
  main.dart
  app.dart
  core/                    # config, errors, Dio, Action Cable, storage, theme, l10n, router, widgets
  features/
    auth/
      domain/              # entities, repository contracts, use cases
      data/                # DTOs, remote datasource, repository impl
      presentation/        # Riverpod notifiers, pages, widgets
    dashboard/
    leave/
    team/
    chat/
    documents/
    documents_rh/
    dossiers/
    notifications/
    settings/
    admin_users/
    admin_teams/
    admin_business_units/
    admin_projects/
```

**Dependency rule:** `presentation` → `domain` ← `data`. Presentation never imports Dio, DTOs, or `flutter_secure_storage`. Data never imports Flutter widgets. Domain has no Flutter, Dio, or Riverpod.

**State:** Riverpod. `Provider` for use cases and repositories. `Notifier` / `AsyncNotifier` for screens. `AsyncValue` for loading / data / error. Session is a synchronous `Notifier` hydrated from secure storage at startup.

**Navigation:** `go_router` with a `StatefulShellRoute` (bottom nav). Role redirects copy Angular guards (`auth.guard`, `password.guard`, `manager.guard`, `rh.guard`, `admin.guard`).

```
isAdmin    = role == admin
isRh       = rh || admin
isManager  = manager || rh || admin
```

Bottom nav (all signed-in users): Home, Leave, Team, Messages, More. More holds documents, settings, and role-gated RH/admin items. Leave-review badge and RH document-queue badge sit on More (or on the review destination when visible).

## Networking and auth

One `Dio` client. Base URL from `--dart-define=API_BASE_URL=...`.

| Flavor | Typical base URL |
|---|---|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator / desktop | `http://localhost:3000` |
| staging / prod | HTTPS gateway |

Interceptor attaches `Authorization: Bearer <jwt>`. On `401`, clear session and send the router to `/login`. Login (`POST /auth/login`) is the only public HTTP call.

JWT + user JSON live in `flutter_secure_storage` (keys `alize.token`, `alize.user`), matching the Angular `localStorage` contract so a future token refresh can stay compatible. Language and theme may use ordinary prefs.

Forced first login: if `user.must_change_password`, the shell is unreachable until `PATCH /auth/password` succeeds.

**Chat realtime:** Action Cable on the gateway, `ws(s)://<host>/cable?token=<jwt>`, channel `ChatChannel`. REST is the write path (`POST /auth/conversations/:id/messages`). The socket only delivers `{ type: "message", conversation_id, message }`. If the socket is down, send still succeeds; the peer sees the message on the next list fetch.

**Notifications:** same as web — poll `GET /auth/notifications` about every 20s while the app is in the foreground. Queue badges poll leave-team and document-inbox the same way. Push is out of scope.

**Backend gap:** `NotificationsController#index` exists but `auth-service` routes only declare `PATCH notifications/:id/read`. Add `GET notifications` so the bell works (Angular already calls it).

No other backend work. No new endpoints. CORS does not apply to native apps. Enable cleartext HTTP for the local gateway in Android debug and iOS debug ATS.

## UI, i18n, chat

Alizé tokens from `frontend/src/styles.css`, not stock Material purple.

- Brand `#460CAD` (dark theme `#8B5CF6`), paper `#F4F2F8`, radius 14px.
- Status color only on chips (`ok` / `warn` / `bad`).
- IBM Plex Sans / Serif when licensed; otherwise a close system stack.
- Light / dark, persisted, default follow OS.

Copy: port `frontend/src/assets/i18n/{fr,en,ar}.json`. Default `fr`. Arabic sets `Directionality` RTL. Persist language.

Chat matches the current web client (not the older “text-only” design note): 1:1 threads, company directory picker, unread badge, text + file attachments, authenticated image preview. Max body 4 000 characters.

Signature pad (settings + RH unlock flow) is a Flutter `CustomPainter` equivalent of `signature-pad.ts`. Document preview/print uses the same field templates as `document-templates.ts` / `document-file.ts`, via `pdf` + `printing` instead of jsPDF.

## Errors and testing

Sealed `Failure` in domain: `network`, `unauthorized`, `notFound`, `validation` (message), `server` (status + message). Data layer maps `DioException`. Repositories return `Result<T>` (`({T? data, Failure? failure})` or a small `Either` — no `dartz`). Notifiers expose `AsyncValue`. UI shows a snackbar / inline error; never a raw Dio message.

Tests: `flutter_test` + `mocktail`. TDD on use cases and repository mapping. Widget tests for login, forced password redirect, and role-gated routes. Manual pass against `docker compose` in `backend/`. No live-backend CI in this plan.

## Out of scope

- New product features (geolocation punch-in, biometric login, offline-first sync, push, group chat, typing indicators).
- Changing Angular or the gateway contract except the missing `GET /notifications` route.
- Melos packages, Flavor-specific backends beyond base URL.
- Rewriting Swagger.
