# Alizé — RH platform

Monorepo for the HR app: Angular UI in `frontend/`, Rails services behind a gateway in `backend/`.

- API: `backend/README.md` — `docker compose up --build` then `http://localhost:3000`
- UI: `frontend/README.md` — `npx ng serve --port 4300`
- Mobile: `mobile/README.md` — `flutter run --dart-define=API_BASE_URL=...` (gateway on `:3000`; Android emulator needs `http://10.0.2.2:3000`)

Keep `backend/.env` local (copy from `backend/.env.example`). Do not commit `config/master.key`.
