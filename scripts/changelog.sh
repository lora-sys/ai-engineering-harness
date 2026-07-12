#!/usr/bin/env bash
# Auto-generate a CHANGELOG.md from merged PRs.
# Usage: scripts/changelog.sh [previous-tag]
set -euo pipefail

# Guard: do not silently overwrite an existing versioned CHANGELOG.md.
# Without this, an accidental run of scripts/changelog.sh would clobber a
# hand-edited v1.0.2 entry with an auto-generated "[Unreleased]" block.
# (This happened during the v1.0.2 release and required a `git checkout`.)
# Use --force to bypass — only when intentionally regenerating from scratch.
FORCE=0
# Collect positional args (skip flags)
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *)       POSITIONAL+=("$arg") ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [[ -f CHANGELOG.md ]] && [[ $FORCE -eq 0 ]]; then
  if grep -qE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md; then
    echo "REFUSED: CHANGELOG.md already has versioned entries." >&2
    echo "  This script overwrites the entire file. Use scripts/changelog-auto.sh" >&2
    echo "  --append for incremental, or pass --force to clobber intentionally." >&2
    exit 2
  fi
fi

prev="${1:-}"
if [[ -z "${prev}" ]]; then
  prev="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
fi

tag="${prev:-HEAD~}"
date="$(date -I)"

{
  echo "# Changelog"
  echo
  echo "## [Unreleased] — ${date}"
  echo
  if [[ -z "${prev}" ]]; then
    echo "- (No previous tag — listing last 30 commits)"
    git log --oneline -30 | sed 's/^/- /'
  else
    # Conventional-commit subject lines, grouped.
    while IFS= read -r subject; do
      case "${subject}" in
        feat*)   prefix="Features" ;;
        fix*)    prefix="Fixes" ;;
        refactor*) prefix="Refactors" ;;
        perf*)   prefix="Performance" ;;
        docs*)   prefix="Docs" ;;
        chore*)  prefix="Chore" ;;
        test*)   prefix="Tests" ;;
        *)       prefix="Other" ;;
      esac
      echo "${prefix}|${subject}"
    done < <(git log "${prev}..HEAD" --pretty=format:"%s")
  fi
} > CHANGELOG.new

# If we have grouping, sort and uniq
if grep -q '|' CHANGELOG.new; then
  sort -u CHANGELOG.new > CHANGELOG.tmp
  {
    echo "# Changelog"
    echo
    echo "## [Unreleased] — ${date}"
    echo
    current=""
    while IFS='|' read -r group subject; do
      if [[ "${group}" != "${current}" ]]; then
        [[ -n "${current}" ]] && echo
        echo "### ${group}"
        current="${group}"
      fi
      echo "- ${subject}"
    done < <(tail -n +5 CHANGELOG.tmp)
  } > CHANGELOG.md
else
  mv CHANGELOG.new CHANGELOG.md
fi

rm -f CHANGELOG.new CHANGELOG.tmp
echo "Wrote: CHANGELOG.md"
