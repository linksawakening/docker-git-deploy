# Maple Proxy service recipe for docker-git-deploy deployment repos

Maple Proxy is an OpenSecret Cloud project that proxies LLM API requests to a
Trymaple enclave. It runs as a small HTTP service (port 8080 inside the
container) and expects clients to supply the secret API key via the
`Authorization` header, so the key does not belong in the deployment repo.

Image: `ghcr.io/opensecretcloud/maple-proxy:latest`

## compose.yaml

Create `services/maple-proxy/compose.yaml`:

```yaml
services:
  maple-proxy:
    image: ${MAPLE_PROXY_IMAGE:-ghcr.io/opensecretcloud/maple-proxy:latest}
    container_name: maple-proxy
    restart: unless-stopped
    labels:
      - autoheal=true
    environment:
      TZ: ${TZ:-UTC}
      MAPLE_BACKEND_URL: ${MAPLE_BACKEND_URL:-https://enclave.trymaple.ai}
      MAPLE_ENABLE_CORS: ${MAPLE_ENABLE_CORS:-true}
      RUST_LOG: ${MAPLE_PROXY_RUST_LOG:-info}
    ports:
      - ${MAPLE_PROXY_PORT:-8081}:8080
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

Notes:

- Default host port is `8081` to avoid collision with SearXNG (8080) and Ignis
  (8082) in the same stack.
- `MAPLE_API_KEY` is intentionally omitted. The proxy does not read it from env;
  clients must pass it in the `Authorization` header.

## .env.example additions

```dotenv
# --- maple-proxy ---
MAPLE_PROXY_IMAGE=ghcr.io/opensecretcloud/maple-proxy:latest
MAPLE_PROXY_PORT=8081
MAPLE_BACKEND_URL=https://enclave.trymaple.ai
MAPLE_ENABLE_CORS=true
MAPLE_PROXY_RUST_LOG=info
```

## Adding to the root compose

Add this line to the `include:` list in the root `compose.yaml`:

```yaml
include:
  # ... existing services
  - services/maple-proxy/compose.yaml
```

## Validate

```bash
cd <deployment-repo>
docker compose config >/dev/null
```

The only expected warning is from other services whose `.env` secrets are not
set (e.g. `SYNTHETIC_API_KEY`); the Maple Proxy config itself has no required
secrets.
