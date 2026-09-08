# Employee digital signature Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let each employee draw a signature once in Paramètres; lock it after save; let RH/admin unlock it from the dossier so the employee can redraw.

**Architecture:** PNG data-URL plus `signature_locked` on `users` in auth-service. Profile GET/PATCH for the employee; unlock endpoint for RH/admin. Frontend: pointer canvas in Paramètres; preview + unlock on Dossiers. Login and directory never include the image.

**Tech Stack:** Rails 8 auth-service, Angular 20 canvas (no extra library), existing JWT gateway, existing notifications.

**Do not commit** unless the user asks. Rebuild `auth-service` after backend changes. Verify with curl + `npx ng build`.

---

### Task 1: Migration, model, JSON, APIs

**Files:**
- Create: `backend/auth-service/db/migrate/20260908000004_add_signature_to_users.rb`
- Modify: `backend/auth-service/app/models/user.rb`
- Modify: `backend/auth-service/app/models/notification.rb`
- Modify: `backend/auth-service/app/controllers/application_controller.rb`
- Modify: `backend/auth-service/app/controllers/profiles_controller.rb`
- Modify: `backend/auth-service/app/controllers/users_controller.rb`
- Modify: `backend/auth-service/config/routes.rb`

Columns: `signature_png` text nullable; `signature_locked` boolean not null default false.

User: allow blank PNG; if present must match `\Adata:image/png;base64,[A-Za-z0-9+/=\s]+\z` and size ≤ 200_000.

`profile_json` / `dossier_json` add `signature_png`, `signature_locked`. Never add them to `user_json` / `member_json`.

Profile PATCH: if `signature_png` present and locked → 403. Else assign PNG and set locked true.

`POST users/:id/signature/unlock`: require_admin_or_rh; set locked false; notify `signature_unlocked`.

---

### Task 2: Frontend pad + Paramètres + Dossiers

**Files:**
- Create: `frontend/src/app/shared/signature-pad.ts`
- Modify: settings, dossiers, models, profile.service, labels if needed, styles, swagger, README

Pad: canvas, pointer events, `touch-action: none`, clear, `toDataURL('image/png')`, dirty flag.

Paramètres: pad when `!signature_locked || !signature_png`; else `<img>`.

Dossiers: preview + unlock button when locked.

---

### Task 3: Rebuild and verify

Rebuild auth-service. Employee save then PATCH again → 403. RH unlock → employee can save. `/auth/me` has no `signature_png`. `npx ng build`.
