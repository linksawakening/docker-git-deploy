# docker-git-deploy repository maintenance

This reference captures the non-trivial steps for renaming the framework, rewriting commit authors, and cleaning duplicate template files. Use it when the project itself needs structural surgery.

## Rename the project and rewrite history

Use `git-filter-repo` (preferred over `git filter-branch`). Install it if missing:

```bash
uv tool install git-filter-repo
# or
pip3 install git-filter-repo
```

### Rewrite authors across the entire history

```bash
git filter-repo \
  --name-callback 'return b"linksawakening"' \
  --email-callback 'return b"linksdigitalawakening@gmail.com"' \
  --force
```

`--force` is required because the repo is not a fresh clone.

### Rename directories, files, and text content in one pass

Example: rename `dockerlab-deploy` → `docker-git-deploy` and the `dockerlab` CLI → `docker-git-deploy`.

```bash
cat > /tmp/rename-expr.txt <<'EOF'
dockerlab-deploy==>docker-git-deploy
dockerlab==>docker-git-deploy
DockerLab Deploy==>Docker Git Deploy
DockerLab==>Docker Git
EOF

git filter-repo \
  --path-rename dockerlab-deploy-skill/:docker-git-deploy-skill/ \
  --path-rename dockerlab-deploy-skill/scripts/dockerlab:docker-git-deploy-skill/scripts/docker-git-deploy \
  --path-rename dockerlab-deploy-skill/templates/dockerlab-deploy-starter:docker-git-deploy-skill/templates/docker-git-deploy-starter \
  --path-rename dockerlab-deploy-skill/templates/systemd/dockerlab-deploy.service:docker-git-deploy-skill/templates/systemd/docker-git-deploy.service \
  --path-rename dockerlab-deploy-skill/templates/systemd/dockerlab-deploy.timer:docker-git-deploy-skill/templates/systemd/docker-git-deploy.timer \
  --replace-text /tmp/rename-expr.txt \
  --name-callback 'return b"linksawakening"' \
  --email-callback 'return b"linksdigitalawakening@gmail.com"' \
  --force
```

Pitfalls:

- `git-filter-repo` removes the `origin` remote; re-add it after rewriting.
- Longer replacement strings must be listed before shorter ones that are substrings of them.
- The rewrite does **not** touch untracked or gitignored files. Run `grep -RI '<old-name>' . --exclude-dir=.git` afterward and fix any leftovers by hand, then amend or add a new commit.

## Rename the GitHub repository

```bash
gh repo rename <new-name> -R <owner>/<old-name> --yes
```

Then update the local remote and force-push:

```bash
git remote add origin https://github.com/<owner>/<new-name>.git
git fetch origin
git push -u origin main --force
```

## Clean duplicate template files

After the rename, audit the framework template folder for redundant copies:

```bash
find docker-git-deploy-skill/templates -type f | sort
```

Common redundancies to remove:

- `templates/.github/workflows/validate.yaml` — the starter template already ships its own workflow.
- `templates/services/<name>/` — prefer the canonical service example at the repo root `services/<name>/`, and keep only the starter in `templates/docker-git-deploy-starter/`.
- Unrelated docs that wandered in from other projects (e.g. a Synthetic quota reference).

Verify no stale strings remain:

```bash
grep -RI '<old-name>' . --exclude-dir=.git
```

## Rename the local skill directory

The Hermes skill directory name should match the skill/repo name:

```bash
mv ~/.hermes/skills/devops/dockerlab-deploy ~/.hermes/skills/devops/docker-git-deploy
```

If the skill is nested inside the repo folder (as this one is), the working path becomes `~/.hermes/skills/devops/docker-git-deploy/docker-git-deploy-skill/`.

## Check the final shape

```bash
git log --format='%h %an <%ae> %s' -10
git remote -v
grep -RI '<old-name>' . --exclude-dir=.git
```
