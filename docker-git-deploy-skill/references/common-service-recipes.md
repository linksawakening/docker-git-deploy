# Common service recipes for docker-git-deploy deployment repos

This reference collects minimal, known-good Docker Compose fragments for
services that frequently show up in docker-git-deploy stacks.

## Uptime Kuma

Image: `louislam/uptime-kuma:1`

```yaml
services:
  uptime-kuma:
    image: ${UPTIME_KUMA_IMAGE:-louislam/uptime-kuma:1}
    container_name: uptime-kuma
    restart: unless-stopped
    labels:
      - autoheal=true
    environment:
      TZ: ${TZ:-UTC}
      DATA_DIR: /app/data
    volumes:
      - ${UPTIME_KUMA_DATA_PATH:-./data/uptime-kuma}:/app/data
    ports:
      - ${UPTIME_KUMA_PORT:-3001}:3001
    healthcheck:
      test: ["CMD", "node", "extra/healthcheck.js"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 40s
```

`.env.example` additions:

```dotenv
# --- uptime-kuma ---
UPTIME_KUMA_IMAGE=louislam/uptime-kuma:1
UPTIME_KUMA_DATA_PATH=./data/uptime-kuma
UPTIME_KUMA_PORT=3001
```

## Ignis (Obsidian as a self-hosted web app)

Image: `nobbe/ignis:latest`

> Ignis serves plain HTTP. The upstream docs recommend putting a reverse proxy
> (Caddy, nginx, Authelia, Cloudflare Tunnel, etc.) in front and not exposing it
> directly to the internet.

```yaml
services:
  ignis:
    image: ${IGNIS_IMAGE:-nobbe/ignis:latest}
    container_name: ignis
    restart: unless-stopped
    labels:
      - autoheal=true
    environment:
      TZ: ${TZ:-UTC}
      IGNIS_HOST: ${IGNIS_HOST:-0.0.0.0}
      IGNIS_PORT: ${IGNIS_PORT:-8080}
    volumes:
      - ${IGNIS_DATA_PATH:-./data/ignis}:/app/data
    ports:
      - ${IGNIS_PORT:-8080}:8080
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

`.env.example` additions:

```dotenv
# --- ignis ---
IGNIS_IMAGE=nobbe/ignis:latest
IGNIS_DATA_PATH=./data/ignis
IGNIS_HOST=0.0.0.0
IGNIS_PORT=8080
```

## Adding a recipe to a deployment repo

1. Create `services/<name>/compose.yaml` in the deployment repo.
2. Add any new `${VAR}` references to `.env.example` with sensible defaults.
3. Add `- services/<name>/compose.yaml` to the `include:` list in the root
   `compose.yaml`.
4. Validate with `docker compose config >/dev/null`.
5. Commit and push.
