# Running new_backend with Docker

This is the "months from now, before a demo, I forgot everything" guide.

## First-time setup

1. `cd new_backend`
2. Copy the example env file and fill in real values:
   ```
   cp .env.example .env
   ```
   For local dev the defaults mostly work — just make sure `POSTGRES_PASSWORD`
   matches between `.env` and `DATABASE_URL`, and fill in a real `JWT_SECRET`
   and the `CLOUDINARY_*` values.
3. Build and start everything:
   ```
   docker compose up --build
   ```
   First run will take a minute or two (downloading the Postgres+PostGIS
   image, installing npm packages). You'll see the `db` container's
   healthcheck passing before the `backend` container starts — that's
   `depends_on: condition: service_healthy` doing its job.
4. In a **second terminal**, run the database migration (this creates all the
   tables — it only needs to be done once per fresh database):
   ```
   docker compose exec backend npm run migrate:latest
   ```
5. Check it worked:
   ```
   curl http://localhost:4000/health
   ```
   You should see `{"status":"ok","database":"connected"}`.

## Everyday commands

| What you want to do | Command |
|---|---|
| Start everything (after first-time setup) | `docker compose up` |
| Start in the background | `docker compose up -d` |
| Stop everything | `docker compose down` |
| Stop AND delete the database data | `docker compose down -v` |
| See backend logs | `docker compose logs -f backend` |
| Run a new migration you just wrote | `docker compose exec backend npm run migrate:latest` |
| Roll back the last migration | `docker compose exec backend npm run migrate:rollback` |
| Run the test suite | `docker compose exec backend npm test` |
| Open a shell inside the backend container | `docker compose exec backend sh` |
| Connect to Postgres directly (e.g. with a GUI tool) | host `localhost`, port `5544`, using the `POSTGRES_*` values from `.env` |

## Why it's set up this way (for interview answers)

- **Multi-stage Dockerfile**: the first stage installs `node_modules`, the
  second stage only copies in the *result* of that (not npm's cache, not dev
  tools). Smaller final image, and Docker can reuse the cached "install"
  layer when you only change your own code.
- **`postgis/postgis` image instead of plain `postgres`**: PostGIS is a
  Postgres extension for geography/location queries (used for "messes near
  me"). The plain Postgres image doesn't include it, and installing it by
  hand inside a container is fiddly — using an image that already has it
  baked in is simpler and more reliable.
- **Named volume (`messhub_pg_data`)**: without this, every `docker compose
  down` (or container restart) would wipe your database. The volume lives
  outside the container's filesystem, so it survives.
- **Healthcheck + `depends_on: condition: service_healthy`**: "the container
  started" and "Postgres is actually ready to accept connections" are two
  different moments — there's a real gap between them. Without the
  healthcheck, the backend could start and try to connect before Postgres is
  ready, and migrations would fail on a race condition. The healthcheck (via
  `pg_isready`) makes Compose wait for the real thing.
- **Timezone set in two places**: once on the `db` container itself (`TZ` /
  `PGTZ` env vars — this is Postgres' own default), and once per-connection
  in `db/knexfile.js` (`SET TIME ZONE 'Asia/Kolkata'`). The per-connection
  one is what actually matters for the app's correctness (see the schema plan
  for why — this is what prevents the whole class of "meal marked absent 5.5
  hours too early/late" bugs). The container-level one is just a backup, in
  case something ever connects to this database without going through our
  app's connection pool.
- **`docker-compose.yml` lives inside `new_backend/`, not the repo root**:
  keeps `new_backend/` fully self-contained — you can hand someone just this
  folder and they can run it, without needing anything from the old
  `backend/` folder or the rest of the repo.
