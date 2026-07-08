#!/bin/bash
set -euo pipefail

# generate-separate-deployment.sh
# Generate a separate Docker Git deployment repo for a real production host.
# Uses the starter template and the framework's own init-deployment.sh.

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<EOF
Usage: $0 --target-dir <dir> --repo-name <name> --host-name <host> --org <org>

Generate a new pure-config deployment repo ready to push to GitHub.
EOF
}

TARGET_DIR=""
REPO_NAME=""
HOST_NAME=""
ORG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target-dir) TARGET_DIR="$2"; shift 2 ;;
        --repo-name) REPO_NAME="$2"; shift 2 ;;
        --host-name) HOST_NAME="$2"; shift 2 ;;
        --org) ORG="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1"; usage; exit 1 ;;
    esac
done

[[ -n "$TARGET_DIR" && -n "$REPO_NAME" && -n "$HOST_NAME" && -n "$ORG" ]] || {
    usage
    exit 1
}

export TARGET_DIR REPO_NAME HOST_NAME ORG
"$SKILL_DIR/scripts/init-deployment.sh"

# Remove the stale leftover from earlier iterations if present.
rm -f "$TARGET_DIR/bootstrap-*.sh" 2>/dev/null || true

cat <<EOF

Deployment repo generated at: $TARGET_DIR

Next steps:
  1. cd $TARGET_DIR
  2. git init && git add . && git commit -m "Initial docker-git-deploy deployment"
  3. git remote add origin https://github.com/$ORG/$REPO_NAME.git
  4. git push -u origin main
  5. Give the bootstrap command in README.md to the user for $HOST_NAME
EOF
