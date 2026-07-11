#!/usr/bin/env bash
# Auto-generate a CHANGELOG.md from merged PRs.
# Usage: scripts/changelog.sh [previous-tag]
set -euo pipefail

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
