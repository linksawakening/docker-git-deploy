# SearXNG recipe for docker-git-deploy

A privacy-respecting, self-hosted metasearch engine.

Image: `searxng/searxng:latest`

## compose.yaml

```yaml
services:
  searxng:
    image: ${SEARXNG_IMAGE:-searxng/searxng:latest}
    container_name: searxng
    restart: unless-stopped
    labels:
      - autoheal=true
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    security_opt:
      - no-new-privileges:true
    environment:
      TZ: ${TZ:-UTC}
    volumes:
      - ${SEARXNG_DATA_PATH:-./data/searxng}:/etc/searxng/settings.yml:ro
    ports:
      - ${SEARXNG_PORT:-8080}:8080
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

## settings.yml

Minimal, no-secret starter config. Mount read-only at `/etc/searxng/settings.yml`.

```yaml
use_default_settings: true

server:
  # Non-empty placeholder for deployments that do not rely on secret features.
  secret_key: "not-a-secret"
  limiter: false

search:
  formats:
    - html
    - json

image_proxy: true

redis:
  url: false
```

## .env.example additions

```dotenv
# --- searxng ---
SEARXNG_IMAGE=searxng/searxng:latest
SEARXNG_DATA_PATH=./data/searxng
SEARXNG_PORT=8080
SEARXNG_BASE_URL=http://localhost:8080
```

## Notes

- The container's `/etc/searxng` is replaced by the mounted file; mounting only
  `settings.yml` as a single file keeps the rest of the image defaults intact.
- Use `cap_drop: ALL` plus the minimal `cap_add` the image needs to reduce attack
  surface.
- Healthcheck endpoint is `/healthz` on the container's own port.
