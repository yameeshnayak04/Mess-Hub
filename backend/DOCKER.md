# Running new_backend with Docker

The "months from now, before a demo, I've forgotten everything" guide.

Every command below is run from inside the `new_backend/` folder.

> **Which compose file?** `docker-compose.dev.yml` is the committed, canonical
> setup — always pass it with `-f`. Plain `docker-compose.yml` is git-ignored
> and reserved for your own local tweaks; copy the dev file to that name if you
> ever want changes that should not be committed.

## First-time setup

1. `cd new_backend`
2. Create your env file and fill in real values:
   ```
   cp .env.example .env
   ```
   For local development the defaults mostly work. Make sure
   `POSTGRES_PASSWORD` matches the one inside `DATABASE_URL`, and put real
   values in `JWT_SECRET`, `CRON_SECRET` and the `CLOUDINARY_*` keys.
3. Build and start both containers:
   ```
   docker compose -f docker-compose.dev.yml up --build
   ```
   The first run takes a couple of minutes (pulling the Postgres+PostGIS image,
   installing npm packages). You will see the `db` healthcheck pass before the
   `backend` container starts — that is `depends_on: condition: service_healthy`
   doing its job.
4. In a **second terminal**, create the tables. This is only needed once per
   fresh database:
   ```
   docker compose -f docker-compose.dev.yml exec backend npm run migrate:latest
   ```
5. Check it worked:
   ```
   curl http://localhost:4000/health
   ```
   You should get `{"status":"ok","database":"connected"}`.

## Everyday commands

| What you want to do                     | Command                                                                            |
| --------------------------------------- | ---------------------------------------------------------------------------------- |
| Start everything                        | `docker compose -f docker-compose.dev.yml up`                                      |
| Start in the background                 | `docker compose -f docker-compose.dev.yml up -d`                                   |
| Stop everything (keeps your data)       | `docker compose -f docker-compose.dev.yml stop`                                    |
| Stop and remove the containers          | `docker compose -f docker-compose.dev.yml down`                                    |
| **Wipe the database completely**        | `docker compose -f docker-compose.dev.yml down -v`                                 |
| Rebuild after changing code             | `docker compose -f docker-compose.dev.yml up -d --build`                           |
| Watch the logs                          | `docker compose -f docker-compose.dev.yml logs -f backend`                         |
| Apply new migrations                    | `docker compose -f docker-compose.dev.yml exec backend npm run migrate:latest`     |
| Undo the last migration                 | `docker compose -f docker-compose.dev.yml exec backend npm run migrate:rollback`   |
| Shell inside the container              | `docker compose -f docker-compose.dev.yml exec backend sh`                         |
| Open psql                               | `docker compose -f docker-compose.dev.yml exec db psql -U messhub_user -d messhub` |
| Connect a GUI tool (TablePlus, pgAdmin) | host `localhost`, port `5544`, credentials from `.env`                             |

## Running the tests

The unit tests and the API test both talk to the database on `localhost:5544`,
so the stack needs to be up first.

```
docker compose -f docker-compose.dev.yml up -d          # stack running
npm test                                                # 26 unit tests
CRON_SECRET_FOR_TEST=$(grep '^CRON_SECRET=' .env | cut -d= -f2) npm run test:api
```

`npm test` covers the billing maths (both pure functions and against real
Postgres). `npm run test:api` drives every HTTP route end to end and prints
response-time percentiles at the end.

## Troubleshooting

**"The build says it succeeded but my change isn't there."**
Check the build's _exit code_, not just the last few lines — if you pipe the
output through `tail`, the pipe hides a failure and `docker compose up` will
happily keep running the previous image:

```
docker compose -f docker-compose.dev.yml build backend; echo "exit=$?"
```

**"Migrations fail with a relation-already-exists error."**
The database already has the schema. Either skip the migration step or wipe and
start over with `down -v` followed by `up` and `migrate:latest`.

**"Port 4000 or 5544 is already in use."**
Something else is on that port — change `PORT` in `.env`, or the left-hand side
of the port mapping in `docker-compose.dev.yml`.

## Why it is set up this way (interview answers)

- **Multi-stage Dockerfile** — the first stage installs `node_modules`, the
  second copies only the _result_ across. Smaller final image, and Docker can
  reuse the cached install layer when only your own code changed.
- **`npm ci` rather than `npm install`** — `ci` installs exactly what
  `package-lock.json` pins and fails if the two disagree, so the image is
  reproducible instead of quietly drifting.
- **Runs as the `node` user, not root** — if the app is ever compromised, the
  attacker does not get root inside the container.
- **`postgis/postgis` image instead of plain `postgres`** — PostGIS is the
  extension that makes "messes near me" possible. Installing it by hand inside
  a plain Postgres container is fiddly; using an image that already has it is
  simpler and more reliable.
- **Named volume `messhub_pg_data`** — without it, every `down` would wipe the
  database. The volume lives outside the container, so data survives.
- **Healthcheck + `condition: service_healthy`** — "the container started" and
  "Postgres is ready for connections" are two different moments, with a real
  gap between them. Without the healthcheck the backend can start first and
  migrations fail on a race. `pg_isready` checks the real thing.
- **Timezone set in two places** — on the `db` container (`TZ`/`PGTZ`) and
  per-connection in `db/knexfile.js`. The per-connection one is what actually
  protects correctness; the container-level one is a backup for anything that
  connects without going through the app's pool.
