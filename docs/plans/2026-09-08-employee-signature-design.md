# Employee digital signature

Each employee draws a handwritten signature once in Paramètres. After save they still see the picture, but the pad is gone. RH or admin can reopen it from Dossiers so the employee can draw a new one. Not stamped on documents yet.

## Employee — Paramètres

New card **Signature**.

- No signature, or unlocked: canvas (mouse and touch), Effacer, Enregistrer. Save is disabled until they have drawn.
- After save: static PNG only. Copy: “Signature enregistrée. Seule la RH peut autoriser une modification.”
- They cannot PATCH a new image while locked.

## RH / admin — Dossiers

New card **Signature** on `/dossiers/:id`.

- Preview of the current PNG, or “Aucune signature”.
- If locked: button **Autoriser une nouvelle signature**. Keeps the old image until the employee saves a replacement. Employee is notified.
- RH does not draw for the employee.

## Data and APIs (auth-service)

On `users`: `signature_png` (text, `data:image/png;base64,…`), `signature_locked` (boolean, default false).

- `GET /auth/profile` includes `signature_png` and `signature_locked`.
- `PATCH /auth/profile` with `signature_png` only when unlocked or empty; then sets `signature_locked` true. 403 if locked. Max ~200 KB. PNG data-URL only.
- `POST /auth/users/:id/signature/unlock` — RH + admin.
- `GET /auth/users/:id` (dossier) includes the same two fields.

`user_json` / login / `/auth/me` / directory / `member_json` never include the PNG.

Notification kind `signature_unlocked`, link `/parametres`.

## Out of scope

Stamping on leave/documents, typed/uploaded signatures, cryptographic certificates, RH drawing on behalf of the employee.
