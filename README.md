# Alizé — RH platform

Monorepo for the HR app: Angular UI in `frontend/`, Rails services behind a gateway in `backend/`.

- API: `backend/README.md` — `docker compose up --build` then `http://localhost:3000`
- UI: `frontend/README.md` — `npx ng serve --port 4300`

Keep `backend/.env` local (copy from `backend/.env.example`). Do not commit `config/master.key`.
