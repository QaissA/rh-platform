# RH Platform — Backend

Microservices backend for the enterprise HR ("RH") platform. Built with Ruby on
Rails (API-only) behind a single API gateway.

## Features (target)

- Log in
- Check leave balance (solde de congés)
- See who is on your team
- Submit leave requests
- Submit administrative-paper requests

> This is the **skeleton**: structure, routes, models, and stub controllers are in
> place. Real business logic (approval workflows, balance accrual, document
> generation, hardened auth) is intentionally not implemented yet.

## Architecture

```
                       ┌─────────────────┐
   client / frontend ──►   api-gateway    │  :3000 (only public entrypoint)
                       │  - validates JWT │
                       │  - forwards      │
                       └───┬────┬────┬────┘
                           │    │    │   forwards X-User-Id / X-User-Role
              /auth/*      │    │    │      /admin-docs/*
                 ┌─────────▼┐  ┌▼────────┐  ┌▼───────────────┐
                 │auth-     │  │leave-   │  │admin-doc-      │
                 │service   │  │service  │  │service         │
                 │users,    │  │congés   │  │admin papers    │
                 │teams,    │  │balance  │  │                │
                 │login,JWT │  │+requests│  │                │
                 └────┬─────┘  └───┬─────┘  └────┬───────────┘
                 postgres-auth  postgres-leave  postgres-admin
```

- **Database per service** (no shared DB, no cross-service SQL joins).
- **Auth**: `auth-service` issues a JWT on login. The gateway validates the JWT on
  every request and forwards the authenticated `user_id` / `role` to downstream
  services via the `X-User-Id` / `X-User-Role` headers. Downstream services trust
  those headers (they are only reachable through the gateway on the internal
  network).

## Services

| Service             | Responsibility                                | DB              |
|---------------------|-----------------------------------------------|-----------------|
| `api-gateway`       | Single entrypoint, JWT validation, proxying   | –               |
| `auth-service`      | Users, teams, login (JWT issuer)              | postgres-auth   |
| `leave-service`     | Leave balance + leave requests                | postgres-leave  |
| `admin-doc-service` | Administrative paper requests                 | postgres-admin  |

## Running with Docker (recommended)

Requires Docker.

```bash
cd backend
cp .env.example .env       # then edit JWT_SECRET / Postgres creds
docker compose up --build
```

The gateway is available at http://localhost:3000. The other services and the
databases are only reachable on the internal compose network.

On first boot each service runs `db:prepare` (create + migrate). `auth-service`
also seeds demo users (all with password `password`):

| Email               | Password   | Role     |
|---------------------|------------|----------|
| `admin@rh.local`    | `password` | admin    |
| `manager@rh.local`  | `password` | manager  |
| `rh@rh.local`       | `password` | rh       |
| `employee@rh.local` | `password` | employee |

…plus four more employees on the Platform team.

## API documentation (Swagger)

Interactive Swagger UI for the whole platform is served by the gateway:

- **Swagger UI:** http://localhost:3000/api-docs
- **OpenAPI spec:** http://localhost:3000/api-docs/v1/swagger.yaml

The spec (hand-written OpenAPI 3.0) lives at
`api-gateway/swagger/v1/swagger.yaml` and documents every route as clients call
it through the gateway. To try authenticated endpoints in the UI: call
`POST /auth/login`, copy the returned `token`, click **Authorize**, and paste it.

## API (through the gateway)

All routes below are prefixed by the gateway; e.g. `POST http://localhost:3000/auth/login`.

| Method | Path                    | Auth   | Description                          |
|--------|-------------------------|--------|--------------------------------------|
| GET    | `/health`               | no     | Gateway health                       |
| POST   | `/auth/login`           | no     | Log in, returns `{ token, user }`    |
| GET    | `/auth/me`              | yes    | The current authenticated user       |
| GET    | `/auth/notifications`   | yes    | Inbox (document ready, leave steps)  |
| PATCH  | `/auth/notifications/:id/read` | yes | Mark a notification as read     |
| GET    | `/auth/teams/mine`      | yes    | Your team + colleagues               |
| GET    | `/auth/profile`         | yes    | Own profile (address, job title, signature) |
| PATCH  | `/auth/profile`         | yes    | Address, job-title request, or signature |
| GET    | `/auth/users`           | rh     | Directory (no salary/IBAN/signature) |
| GET    | `/auth/users/:id`       | rh     | Confidential dossier                 |
| PATCH  | `/auth/users/:id`       | rh     | Update dossier (RH) / org (admin)    |
| POST   | `/auth/users/:id/job-title/accept` | rh | Confirm employee job title  |
| POST   | `/auth/users/:id/job-title/reject` | rh | Refuse employee job title   |
| POST   | `/auth/users/:id/signature/unlock` | rh | Reopen signature for employee |
| DELETE | `/auth/users/:id`       | admin  | Delete a user                        |
| GET    | `/leave/balance`        | yes    | Your remaining leave (solde)         |
| GET    | `/leave/requests`       | yes    | Your leave requests                  |
| POST   | `/leave/requests`       | yes    | Submit a leave request               |
| GET    | `/admin-docs/requests`  | yes    | Your admin-paper requests            |
| POST   | `/admin-docs/requests`  | yes    | Submit an admin-paper request        |

Authenticated requests need the header `Authorization: Bearer <token>`.

### Roles & authorization

Roles are `employee`, `lead`, `manager`, `rh`, `admin`. Leave requests need
**two approvals**: the team/BU manager first (`pending` → `pending_hr`), then RH
(`pending_hr` → `approved`). Until RH confirms, the leave stays pending and the
balance is not debited. Manager or RH refusal closes the request as `rejected`.

### Example

```bash
# 1. Log in
TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"employee@rh.local","password":"password"}' | jq -r .token)

# 2. Check leave balance
curl http://localhost:3000/leave/balance -H "Authorization: Bearer $TOKEN"

# 3. Submit a leave request
curl -X POST http://localhost:3000/leave/requests \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"start_date":"2026-08-01","end_date":"2026-08-05","reason":"vacation"}'
```

## Running a single service locally (without Docker)

Requires Ruby 3.4 and a local Postgres.

```bash
cd backend/auth-service
bundle install
bin/rails db:prepare
bin/rails server -p 3001
```

Set `DATABASE_URL` and `JWT_SECRET` in the environment as needed. Local service
ports assumed by the gateway when run outside Docker: auth `3001`, leave `3002`,
admin-doc `3003` (see `api-gateway/app/services/service_registry.rb`).

## Where to add real logic

- **Auth hardening / refresh tokens**: `auth-service/app/controllers/sessions_controller.rb`,
  `auth-service/app/services/json_web_token.rb`.
- **Leave balance accrual & approval workflow**: `leave-service/app/controllers/*`,
  `leave-service/app/models/*`.
- **Document generation / status transitions**: `admin-doc-service/app/*`.
- **Routing / new services**: `api-gateway/app/services/service_registry.rb`,
  `api-gateway/config/routes.rb`.

## Next steps (out of scope for this skeleton)

- Real authorization rules (roles/permissions), refresh tokens.
- Actual leave-balance computation and approval flow.
- Admin-document generation and status lifecycle.
- Tests (RSpec), CI, and the `frontend/` app.
