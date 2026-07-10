# Hindsight recipe for docker-git-deploy

Hindsight is a conversational memory / knowledge agent backed by a local
PostgreSQL-ish store and an external LLM provider. In this recipe it uses the
Synthetic API (OpenAI-compatible endpoint) as the LLM backend.

Image: `ghcr.io/vectorize-io/hindsight:latest`

## compose.yaml

```yaml
volumes:
  hindsight_pg_data:

services:
  hindsight:
    image: ${HINDSIGHT_IMAGE:-ghcr.io/vectorize-io/hindsight:latest}
    container_name: hindsight
    restart: unless-stopped
    labels:
      - autoheal=true
    environment:
      TZ: ${TZ:-UTC}
      HINDSIGHT_API_LLM_PROVIDER: openai
      HINDSIGHT_API_LLM_BASE_URL: https://api.synthetic.new/openai/v1
      HINDSIGHT_API_LLM_API_KEY: ${SYNTHETIC_API_KEY}
      HINDSIGHT_API_LLM_MODEL: ${HINDSIGHT_MODEL:-syn:small:text}
      HINDSIGHT_API_LLM_MAX_CONCURRENT: ${HINDSIGHT_MAX_CONCURRENT:-1}
      HINDSIGHT_API_LLM_TIMEOUT: ${HINDSIGHT_TIMEOUT:-300}
    volumes:
      - hindsight_pg_data:/home/hindsight/.pg0
    ports:
      - ${HINDSIGHT_PORT_HTTP:-8888}:8888
      - ${HINDSIGHT_PORT_RPC:-9999}:9999
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:8888/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
```

## .env.example additions

```dotenv
# --- hindsight ---
HINDSIGHT_IMAGE=ghcr.io/vectorize-io/hindsight:latest
HINDSIGHT_PORT_HTTP=8888
HINDSIGHT_PORT_RPC=9999
HINDSIGHT_MODEL=syn:small:text
HINDSIGHT_MAX_CONCURRENT=1
HINDSIGHT_TIMEOUT=300
# Required: API key for Synthetic (https://api.synthetic.new). Replace on host.
SYNTHETIC_API_KEY=replace-me
```

## Notes

- Uses a top-level named Docker volume `hindsight_pg_data` for its embedded
  database. docker-git-deploy handles named volumes fine; just declare the
  volume in the same service compose file.
- `SYNTHETIC_API_KEY` is required and must be replaced in `.env` on the host.
- The HTTP health endpoint is at `/health` on port `8888`.
- `HINDSIGHT_API_LLM_BASE_URL` assumes Synthetic's OpenAI-compatible endpoint;
  change provider settings for a different backend.
