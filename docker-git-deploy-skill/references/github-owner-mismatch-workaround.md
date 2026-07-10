# GitHub owner mismatch workaround for docker-git-deploy repos

When the authenticated GitHub user does not match the requested repository
owner, `gh repo create armstrys/docker-git-deploy-rimini` fails with:

```
GraphQL: linksawakening cannot create a repository for armstrys.
```

`gh repo create` also has no `--owner` flag for user accounts, so the agent
needs a fallback recipe.

## Recommended fallback

1. Create the repo under the authenticated account instead:

```bash
gh repo create docker-git-deploy-rimini --private \
  --description "Docker Git deployment configuration for rimini"
```

2. Invite the intended owner (`armstrys`) as a collaborator with admin
   permission:

```bash
curl -fsSL -X PUT \
  -H "Authorization: token $(gh auth token)" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/linksawakening/docker-git-deploy-rimini/collaborators/armstrys \
  -d '{"permission":"admin"}'
```

3. Update the bootstrap URL in `README.md` to point at the actual repository
   location under the authenticated account:

```bash
# /home/hermes/docker-git-deploy-rimini/README.md
# change:
# --deployment-repo https://github.com/armstrys/docker-git-deploy-rimini.git
# to:
# --deployment-repo https://github.com/linksawakening/docker-git-deploy-rimini.git
```

4. Commit and push:

```bash
git remote add origin https://github.com/linksawakening/docker-git-deploy-rimini.git
git push -u origin main
```

5. Optional: transfer the repository to the intended owner through the GitHub
   web UI (Settings → Danger Zone → Transfer ownership). The API transfer
   endpoint only works for organizations, not personal accounts.

## Follow-up for the user

Tell the user:
- The repo is currently under `linksawakening/docker-git-deploy-rimini`.
- `armstrys` has a pending admin invitation.
- The user can accept the invitation and optionally transfer the repo to
  `armstrys` via the GitHub UI.
- The README bootstrap command already points to the currently accessible URL.
