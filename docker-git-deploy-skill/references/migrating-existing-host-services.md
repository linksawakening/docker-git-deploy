# Migrating existing host services into a docker-git-deploy repo

A common homelab pattern: the user already has services running on a host
(`ribeedocker`, `rimini`, etc.) and wants to bring them under GitOps. The
agent should reconcile the new deployment repo with the real running services
rather than inventing fresh defaults.

## Discovery checklist

Before adding services, inspect the actual host configuration:

1. Look for an existing deployment repo or compose files:
   ```bash
   # On the agent host (Hermes)
   find /home/hermes -maxdepth 3 -name "docker-compose.yml" -o -name "compose.yaml"
   find /home/hermes -maxdepth 2 -type d -name "*-deploy"
   ```
2. If one exists, read its `compose.yaml`, `.env.example` (or `.env`), and each
   `services/<name>/compose.yaml` to learn real image tags, ports, volume mounts,
   and environment variables.
3. Check Hindsight memory for service-specific setup notes (SearXNG settings,
   Hindsight Synthetic config, Ignis vault mounts, etc.).

## Decision tree

| Situation | Action |
|-----------|--------|
| Existing `ribeedocker-deploy`-style repo already uses docker-git-deploy | Add/update services there; do not create a second repo for the same host. |
| Existing compose files but no GitOps repo | Create one deployment repo named after the host and port the services into `services/`. |
| User asked for a new repo name that conflicts with host name | Clarify whether `rimini` and `ribeedocker` are the same host. If they are, use the host name as the repo name to avoid confusion. |
| Service has host-specific volume mounts (Synology shares, local source builds) | Preserve them in the deployment repo; document any paths that differ on the production host. |

## Service-specific ribeedocker notes

### SearXNG

- Image: `searxng/searxng:latest`
- Requires a mounted `settings.yml` at `/etc/searxng/settings.yml:ro`.
- Working no-secret config sets `server.secret_key: ""` and `limiter: false`.
- Must enable JSON format for Hermes web search:
  ```yaml
  search:
    formats:
      - html
      - json
  ```
- Use `cap_drop: [ALL]` plus `cap_add: [CHOWN, SETGID, SETUID]`.

### Hindsight (Synthetic-backed)

- Image: `ghcr.io/vectorize-io/hindsight:latest`
- Ports: `8888` (API), `9999` (web UI).
- Environment for Synthetic:
  ```yaml
  HINDSIGHT_API_LLM_PROVIDER: openai
  HINDSIGHT_API_LLM_BASE_URL: https://api.synthetic.new/openai/v1
  HINDSIGHT_API_LLM_API_KEY: ${SYNTHETIC_API_KEY}
  HINDSIGHT_API_LLM_MODEL: syn:small:text
  HINDSIGHT_API_LLM_MAX_CONCURRENT: 1
  HINDSIGHT_API_LLM_TIMEOUT: 300
  ```
- Use a named Docker volume (`pg_data`) for persistence.
- `MAX_CONCURRENT=1` matters for Synthetic's 1-pack plan to avoid 429 errors.

### Ignis

Two deployment patterns are in use; ask which one the user wants:

1. **Prebuilt image** (`nobbe/ignis:latest`): quick, but mounts a single data
   volume. Use for a generic browser Obsidian viewer.
2. **Local source build** from `/home/hermes/projects/ignis-server`: required
   when bind-mounting multiple Synology vault folders (cooking, research-wiki).
   Use `build` instead of `image` and map each vault separately under
   `/vaults/<vault-name>`.

## Pitfalls

- **Guessing default ports/images** can collide with the real running services.
  Always prefer values from the existing working config.
- **Using `nobbe/ignis:latest` blindly** loses Synology vault access if the real
  deployment is the source-built version.
- **Creating a second repo for the same host** (`rimini` vs `ribeedocker`)
  splits authority and confuses bootstrap. Clarify host identity first.
- **Forgetting host-specific environment secrets** (e.g. `SYNTHETIC_API_KEY`)
  in `.env.example`. The deployment repo must declare every variable the host
  needs, even if the value is a placeholder.
