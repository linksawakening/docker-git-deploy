#!/bin/bash
set -euo pipefail

# validate-repo-structure.sh
# Sanity check the docker-git-deploy repo structure. Run from repo root.

fail() { echo "FAIL: $*" >&2; exit 1; }

# Repo root must look like a deployment repo
[[ -f compose.yaml ]] || fail "compose.yaml missing at repo root"
[[ -f .env.example ]] || fail ".env.example missing at repo root"
[[ -f .gitignore ]] || fail ".gitignore missing at repo root"
[[ -d services ]] || fail "services/ directory missing at repo root"

# Framework must live in exactly one named subfolder matching the skill
[[ -d docker-git-deploy-skill ]] || fail "docker-git-deploy-skill/ framework folder missing"
[[ -f docker-git-deploy-skill/SKILL.md ]] || fail "docker-git-deploy-skill/SKILL.md missing"
[[ -f docker-git-deploy-skill/scripts/install.sh ]] || fail "install.sh missing"
[[ -f docker-git-deploy-skill/scripts/docker-git-deploy ]] || fail "docker-git-deploy CLI missing"

# There should be no second SKILL.md in templates or subfolders
skill_md_count=$(find . -name 'SKILL.md' | wc -l)
[[ "$skill_md_count" -eq 1 ]] || fail "Expected exactly one SKILL.md, found $skill_md_count"

# Deployment repo root must not contain executable tooling
for f in deploy.sh validate.sh health-check.sh test-local.sh bootstrap.sh install.sh; do
    [[ -e "$f" ]] && fail "Forbidden executable tooling in repo root: $f"
done

echo "OK: repo structure is valid"
