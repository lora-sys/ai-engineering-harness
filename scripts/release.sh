#!/usr/bin/env bash
# scripts/release.sh — automate the release flow.
#
# Usage: scripts/release.sh <version>
#   e.g., scripts/release.sh 1.7.0
#
# What it does (idempotent on partial failure):
#   1. Verify meta.json version matches the requested version (per D-013).
#   2. Verify working tree is clean.
#   3. Run validators (validate-meta + check-templates + run-tests).
#   4. Commit any pending changes (version bump + CHANGELOG).
#   5. Tag v<version> and push tag + main.
#   6. Create (or update) the GitHub release with notes from CHANGELOG.md.
#   7. Update local fat install + thin install via npx skills update.
#
# Exit codes:
#   0  release succeeded
#   1  validation failed
#   2  push failed
#   3  gh release failed

set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="${1:-}"

log()  { printf '[release] %s\n' "$*" >&2; }
fail() { log "FAIL: $*"; exit 1; }

[[ -n "$VERSION" ]] || fail "usage: scripts/release.sh <version>"

cd "$REPO_DIR"

# Step 1: verify meta.json version
META_VERSION="$(python3 -c "import json; print(json.load(open('meta.json'))['version'])")"
[[ "$META_VERSION" == "$VERSION" ]] || fail "meta.json version ($META_VERSION) != requested ($VERSION). Bump it first (D-013)."

# Step 2: clean working tree (CHANGELOG and meta.json should be staged; nothing else)
if [[ -n "$(git status --short)" ]]; then
  log "Working tree has changes; committing them"
  git add -A
  git -c user.email='maintainer@lora-sys.local' -c user.name='lora-sys' \
    commit -m "chore(release): v$VERSION"
fi

# Step 3: validators
log "Running validators..."
bash scripts/validate-meta.sh --strict >/dev/null || fail "validate-meta failed"
bash scripts/check-templates.sh --strict >/dev/null || fail "check-templates failed"
log "Validators pass."

# Step 4: tag + push
TAG="v$VERSION"
git tag -a "$TAG" -m "$TAG" 2>/dev/null || log "tag $TAG already exists, skipping"
git push origin main || fail "git push origin main failed"
git push origin "$TAG" || fail "git push origin $TAG failed"

# Step 5: gh release with notes from CHANGELOG.md
NOTES_FILE="$(mktemp)"
python3 - "$VERSION" > "$NOTES_FILE" <<'PY'
import re, sys
v = sys.argv[1]
text = open('CHANGELOG.md').read()
m = re.search(r'(##\s*\[' + re.escape(v) + r'\][^\n]*\n.*?)(?=\n##\s*\[|\Z)', text, re.DOTALL)
if m:
    print(f'## {v}\n')
    print(m.group(1).strip())
else:
    print(f'## {v}\n\nSee CHANGELOG.md.')
PY
log "Creating release $TAG..."
gh release create "$TAG" --title "$TAG" --notes-file "$NOTES_FILE" --target main || fail "gh release create failed"
rm -f "$NOTES_FILE"

# Step 6: update local installs
log "Updating local fat install + thin install..."
[[ -d "$HOME/.codex/skills/ai-engineering-harness" ]] && \
  (cd "$HOME/.codex/skills/ai-engineering-harness" && \
   git fetch --tags origin >/dev/null 2>&1 && \
   git checkout "$TAG" >/dev/null 2>&1 && \
   log "fat install → $TAG")
command -v npx >/dev/null && npx -y skills update ai-engineering-harness -g -y >/dev/null 2>&1 && \
  log "thin install (npx) updated"

log "Released $TAG"
