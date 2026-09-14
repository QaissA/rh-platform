# Alizé — Mobile (`alize_mobile`)

Flutter iOS/Android client for the RH platform. Same product as the Angular app
in `frontend/`: login, leave, team, chat, documents, settings, RH dossiers, and
admin org CRUD. Talks **only** to the API gateway on port **3000** — never to
auth-service, leave-service, or admin-doc-service ports.

Package name: `alize_mobile`.

## Prerequisites

- Flutter SDK (Dart 3)
- Backend stack via Docker — see `backend/README.md`

## Run

Start the gateway first, then the app:

```bash
cd backend && docker compose up --build
cd mobile
flutter pub get
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

On Windows PowerShell, chain with `;` instead of `&&`
(`cd backend; docker compose up --build`).

`--dart-define=API_BASE_URL` is optional. `AppConfig` (`lib/core/config/app_config.dart`)
reads that define; if it is empty:

| Host | Default `API_BASE_URL` |
|------|------------------------|
| Android (emulator or device) | `http://10.0.2.2:3000` |
| iOS / everything else | `http://localhost:3000` |

`10.0.2.2` is the emulator’s alias for the host machine. A physical Android
device on the same LAN needs an explicit `--dart-define` with the host’s LAN IP
(the default `10.0.2.2` will not reach your PC).

`wsBaseUrl` is derived from `apiBaseUrl` by replacing the `http` prefix with
`ws` (`http` → `ws`, `https` → `wss`). Chat Action Cable connects to
`<wsBaseUrl>/cable?token=<jwt>`.

The gateway is `http://localhost:3000` (Swagger: `/api-docs`). Keep
`backend/.env` local; copy from `backend/.env.example`.

## Demo users

Seeded by `auth-service` on first boot (same table as `backend/README.md`).
All passwords are `password`:

| Email               | Password   | Role     |
|---------------------|------------|----------|
| `admin@rh.local`    | `password` | admin    |
| `manager@rh.local`  | `password` | manager  |
| `rh@rh.local`       | `password` | rh       |
| `employee@rh.local` | `password` | employee |

…plus four more employees on the Platform team.

## Architecture

Feature-first clean architecture + Riverpod. Each feature owns `domain` /
`data` / `presentation`. Shared kernel under `lib/core`. One public network
edge: **api-gateway :3000**.

```
                       ┌─────────────────┐
   alize_mobile  ──────►   api-gateway    │  :3000 (only public entrypoint)
                       └───┬────┬────┬────┘
                           │    │    │
                    /auth  │    │    │  /admin-docs
                 ┌─────────▼┐  ┌▼────────┐  ┌▼───────────────┐
                 │auth-     │  │leave-   │  │admin-doc-      │
                 │service   │  │service  │  │service         │
                 └──────────┘  └─────────┘  └────────────────┘
```

```
mobile/lib/
  main.dart
  app.dart
  core/                    # config, errors, Dio, Action Cable, storage, theme, l10n, router
  features/
    auth/  dashboard/  leave/  team/  chat/  documents/
    documents_rh/  dossiers/  notifications/  settings/  more/
    admin_users/  admin_teams/  admin_business_units/  admin_projects/
      domain/              # entities, repository contracts, use cases
      data/                # DTOs, remote datasource, repository impl
      presentation/        # Riverpod providers/notifiers, pages, widgets
```

**Dependency rule:** `presentation` → `domain` ← `data`.

- Widgets import `presentation/providers` and domain entities only. No Dio,
  DTOs, or `flutter_secure_storage` in widgets.
- `data/models` know JSON (`fromJson` / `toDomain()`). `domain/entities` do
  **not** have `fromJson`.
- Domain has no Flutter, Dio, or Riverpod. Data never imports Flutter widgets.
- One Dio instance (`dioProvider` in `features/auth/presentation/providers/auth_providers.dart`,
  built by `createDio` in `core/network/dio_client.dart`). Feature datasources
  take `Dio` in the constructor (`LeaveRemote(this._dio)`, etc.).
- Repositories return `Result<T>` (`core/error/result.dart`). Data maps
  `DioException` via `core/network/error_mapper.dart`.
- State: Riverpod `Provider` for use cases and repositories; `Notifier` /
  `AsyncNotifier` for screens.
- Navigation: `go_router` (`core/router/app_router.dart`) with role redirects.
- No `print` of IBAN, salary, signature, or JWT.

Copy `leave/` when in doubt.

## How to add a feature

Work **domain → data → presentation**. Do not put Dio (or gateway paths) in
widgets.

1. **Domain** — entities (plain Dart, no JSON), an abstract repository that
   returns `Result<T>`, and thin use cases that call the repository.
2. **Data** — DTOs with `fromJson` + `toDomain()`; a `*Remote` datasource that
   takes `Dio` and calls **gateway** paths (e.g. `/leave/balance`, `/auth/...`);
   a repository impl that maps DTOs to entities and wraps errors with the
   shared mapper. Do not target auth/leave/admin-doc ports.
3. **Presentation** — providers that wire `ref.watch(dioProvider)` into the
   remote, then repository → use cases → notifiers. Pages/widgets watch those
   providers and render domain entities. Register routes in
   `core/router/app_router.dart` if the feature has a screen. Add copy under
   `assets/i18n/{fr,en,ar}.json`.

```
lib/features/<name>/
  domain/entities|repositories|usecases
  data/models|datasources|repositories
  presentation/providers|pages|widgets
```
