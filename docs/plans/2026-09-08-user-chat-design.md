# 1:1 company chat

Anyone signed in to Alizé can message anyone else. Conversations are stored. Live delivery uses WebSockets. Group chats, attachments, typing indicators, and presence are out of scope.

## Product

- Direct messages only (exactly two participants).
- History is kept; reopening a thread shows previous messages.
- A **Messages** page in the sidebar for every role, plus an unread count on that nav item.
- Only the two participants can read a thread. RH/admin have no audit backdoor.
- Text only, max 4 000 characters. No files, no emoji picker, no edits/deletes in v1.
- Starting a chat: pick a colleague from a company directory (name + job title + role), or open an existing thread.

## Architecture

Messages live in **auth-service** next to `User`. REST goes through the existing gateway (`/auth/...`). The Faraday proxy cannot upgrade WebSockets, so **Action Cable runs on the api-gateway**. Auth-service publishes events to **Redis**; the gateway’s cable process reads Redis and pushes to the recipient’s socket. One public port (`:3000`). JWT already belongs on the gateway.

```
Angular  --HTTP JWT-->  api-gateway  --HTTP X-User-*-->  auth-service
     \--WS /cable?token=JWT-->  api-gateway Action Cable
                                        ^
                                        | Redis pub/sub
                                        |
                                   auth-service broadcast
```

Add a `redis` container to docker-compose. Set `REDIS_URL` on **api-gateway** and **auth-service**. Use the same `channel_prefix` (`alize`) so broadcasts match. Development currently uses the `async` adapter (in-process only); that cannot cross services, so development uses Redis too.

## Data

`conversations`

- `user_a_id`, `user_b_id` (always `user_a_id < user_b_id`)
- unique index on `[user_a_id, user_b_id]`
- foreign keys to `users`

`messages`

- `conversation_id`, `sender_id`, `body` (text), `read_at` (nullable datetime)
- `read_at` is set when the **recipient** opens the thread (all of their unread messages in that thread)

A conversation is created on first send, or via `POST /conversations` with `{ user_id }`.

## HTTP API (auth-service, JWT via gateway)

All require a signed-in user. Payloads never include salary, IBAN, or signature.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/directory` | Company people for the picker: `id`, `email`, `first_name`, `last_name`, `role`, `job_title` (exclude self) |
| GET | `/conversations` | My threads, newest last-message first, with `other` member, `last_message`, `unread_count` |
| POST | `/conversations` | Find or create 1:1 with `{ user_id }` |
| GET | `/conversations/:id/messages` | History (paginated, newest last; `?before_id=` later if needed — v1 can load the last 100) |
| POST | `/conversations/:id/messages` | `{ body }` — persist, mark, broadcast |
| POST | `/conversations/:id/read` | Set `read_at` on unread incoming messages |

403 if the current user is not a participant. 404 if the other user does not exist. 422 if body is blank or too long, or if `user_id` is self.

After persist, auth-service broadcasts on Redis:

```
stream: chat:user:<recipient_id>
payload: { type: "message", conversation_id, message: { id, sender_id, body, created_at, read_at } }
```

Also broadcast to `chat:user:<sender_id>` so other tabs of the sender stay in sync.

## WebSocket (api-gateway)

- Mount Action Cable at `/cable`.
- Identify the connection from `?token=` (browsers cannot set `Authorization` on the WebSocket handshake easily). Reject if the JWT is missing or invalid. `identified_by :current_user_id`.
- `ChatChannel`: `stream_from "chat:user:#{current_user_id}"`. Client does not send messages over the socket (REST is the write path so history never depends on the socket).
- Allow origins: the Angular origin (`localhost:4200` and `:4300` in development).
- Enable `redis` gem on gateway and auth-service.

If Redis or the socket is down, sending still succeeds over HTTP; the other person sees the message on refresh or next `GET /conversations`.

## Frontend

- Route `/messages` (auth only, all roles). Optional `?user=:id` opens/finds that thread.
- Sidebar: **Messages** with unread badge (sum of `unread_count`, kept live via the socket + a light REST refresh on connect).
- Layout: list of threads on the left, transcript + composer on the right (same visual language as existing widgets: IBM Plex, chips, avatars).
- Directory: typeahead or a “Nouveau message” list using `GET /directory`.
- `@rails/actioncable` consumer, created after login, torn down on logout. URL: `ws://localhost:3000/cable?token=...` (derive from `API_BASE_URL`).
- `PeopleService` can keep using `/directory` for chat; existing RH `users` list stays admin/RH-only.

## Notifications

Do **not** create a bell notification for every DM (noise). The Messages badge is the unread signal. No email.

## Tests

Auth-service request specs:

- Directory excludes self and pay fields.
- Two users can exchange messages; a third user gets 403 on that conversation.
- Cannot DM yourself.
- Unread count increments for the recipient; `/read` clears it.
- Broadcast is invoked (stub `ActionCable.server`).

Gateway: connection rejects a bad token (if a cable test harness is cheap); otherwise rely on a manual check.

Frontend: `npx ng build`. Chat page compiles; no Karma requirement beyond existing smoke test.

## Ops

- docker-compose: `redis:7-alpine`, healthcheck, `REDIS_URL=redis://redis:6379/1` on auth-service and api-gateway.
- Rebuild **auth-service** and **api-gateway** (no volume mounts).
- Do not expose auth-service ports to the host.
