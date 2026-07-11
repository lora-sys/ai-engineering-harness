#!/usr/bin/env bash
# Generate (or refresh) CHANGELOG.md from git history + GitHub Release notes.
#
# Half-automated:
#   - Maintainers review the preview (default) before running --write.
#   - Conventional-commit subjects are categorized automatically.
#   - GitHub Release intro is fetched via the gh CLI when available.
#
# Usage:
#   scripts/changelog-auto.sh                          # preview to stdout
#   scripts/changelog-auto.sh --write                 # write to ./CHANGELOG.md
#   scripts/changelog-auto.sh --out <path>            # write to a custom path
#   scripts/changelog-auto.sh --since-tag v0.1.0      # only versions >= tag
#   scripts/changelog-auto.sh --append                # only newer than existing CHANGELOG.md

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

DO_WRITE=0
APPEND_MODE=0
SINCE_TAG="v0.0.0"
OUTFILE="./CHANGELOG.md"

i=0
args=("$@")
n=$#
while [[ $i -lt $n ]]; do
  arg="${args[$i]}"
  case "$arg" in
    --write)        DO_WRITE=1 ;;
    --append)       APPEND_MODE=1 ;;
    --since-tag)    i=$((i+1)); SINCE_TAG="${args[$i]:-v0.0.0}" ;;
    --out)          i=$((i+1)); OUTFILE="${args[$i]:-./CHANGELOG.md}" ;;
    -h|--help)
      sed -n 2,16p "$0"
      exit 0
      ;;
    --*) echo "unknown arg: $arg" >&2; exit 1 ;;
  esac
  i=$((i+1))
done



# --append: append-only mode, derives SINCE_TAG from existing file
if [[ $APPEND_MODE -eq 1 ]]; then
  TARGET="${OUTFILE}"
  if [[ ! -f "$TARGET" ]]; then
    echo "--append needs an existing CHANGELOG.md; missing: $TARGET" >&2
    exit 1
  fi
  LAST_DOC=$(grep -oE '^## \[(v)?[0-9]+\.[0-9]+\.[0-9]+\]' "$TARGET" | head -1 | sed -E 's/^## \[(v)?([0-9.]+)\]$/v\2/')
  if [[ -n "$LAST_DOC" ]]; then
    # Bump to next patch so LAST_DOC is excluded from output
    BASE="${LAST_DOC#v}"
    MAJOR=$(echo "$BASE" | cut -d. -f1)
    MINOR=$(echo "$BASE" | cut -d. -f2)
    PATCH=$(echo "$BASE" | cut -d. -f3)
    SINCE_TAG="v${MAJOR}.${MINOR}.$((PATCH + 1))"
    echo "append mode: including versions > $SINCE_TAG" >&2
  fi
fi

# Collect tags (chronological, oldest first)
mapfile -t TAGS < <(git tag --sort=creatordate --format='%(refname:short)' 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | tac | sort -V)
if [[ ${#TAGS[@]} -eq 0 ]]; then
  echo "no semver tags yet; nothing to do" >&2
  exit 1
fi

# Filter to >= SINCE_TAG
FILTERED=()
SINCE_V="${SINCE_TAG#v}"
for t in "${TAGS[@]}"; do
  tv="${t#v}"
  if [[ "$(printf '%s\n%s\n' "$SINCE_V" "$tv" | sort -V | head -1)" == "$SINCE_V" ]]; then
    FILTERED+=("$t")
  fi
done
TAGS=("${FILTERED[@]}")
[[ ${#TAGS[@]} -eq 0 ]] && { echo "no tags >= $SINCE_TAG; nothing to do" >&2; exit 1; }

# Categorize a subject line based on conventional commit prefix
section_for() {
  local s="$1"
  local p
  p=$(echo "$s" | sed -E 's/^([a-zA-Z][a-zA-Z]+)(\([^)]+\))?[!:] .*/\1/')
  case "$p" in
    feat|feature|features) echo Added ;;
    fix|fixes|bugfix|bug)  echo Fixed ;;
    refactor|rfctr)        echo Changed ;;
    perf)                  echo Performance ;;
    docs|doc)              echo Documentation ;;
    test|tests)            echo Tests ;;
    chore)                 echo Maintenance ;;
    build)                 echo Build ;;
    ci)                    echo CI ;;
    style)                 echo Style ;;
    revert)                echo Reverted ;;
    *)                     echo Changed ;;
  esac
}

strip_prefix() {
  echo "$1" | sed -E 's/^[a-zA-Z][a-zA-Z]+(\([^)]+\))?[!:] //'
}

# Pull the GitHub release "What's new" first prose line
release_intro() {
  local tag="$1"
  if ! command -v gh >/dev/null 2>&1; then return 0; fi
  if ! gh auth status >/dev/null 2>&1; then return 0; fi
  gh release view "$tag" --json body --jq '.body // ""' 2>/dev/null | \
    awk 'BEGIN{found=0}
         /^### What.s new[[:space:]]*$/ {found=1; next}
         found && NF>0 {print; exit}
         found && NF==0 {next}'
}





# Build output
out=""
out+="# Changelog"$'\n'
out+=$'\n'
out+="All notable changes to this project will be documented in this file."$'\n'
out+=$'\n'
out+="The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),"$'\n'
out+="and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)."$'\n'
out+=$'\n'

prev=""
ORDER=(Added Changed Fixed Reverted Deprecated Removed Documentation Performance Build CI Style Tests Maintenance)

for tag in "${TAGS[@]}"; do
  TAG_DATE=$(git log -1 --format='%as' "$tag" 2>/dev/null || date -u +%Y-%m-%d)
  out+="## [$tag] - $TAG_DATE"$'\n'$'\n'

  intro=$(release_intro "$tag")
  if [[ -n "$intro" ]]; then
    out+="### What's new"$'\n'
    out+="$intro"$'\n'$'\n'
  fi

  if [[ -z "$prev" ]]; then
    # First tag in the filtered iteration: find the immediately-preceding
    # semver tag in the full tag list (not the filtered one), and use it
    # as the lower bound so we don't include its commits here.
    FULL_TAGS_SORTED=$(git tag --sort=-v:refname 2>/dev/null | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' || true)
    PREV_TAG=$(echo "$FULL_TAGS_SORTED" | grep -A1 "^${tag}\$" | tail -1)
    if [[ -n "$PREV_TAG" && "$PREV_TAG" != "$tag" ]]; then
      RANGE="${PREV_TAG}..${tag}"
    else
      # No preceding tag; use root commit
      ROOT=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -1)
      RANGE="${ROOT}..${tag}"
    fi
  else
    RANGE="$prev..$tag"
  fi

  declare -A SECTIONS=()
  while IFS= read -r subject; do
    [[ -z "$subject" ]] && continue
    sec=$(section_for "$subject")
    bullet=$(strip_prefix "$subject")
    case "$bullet" in
      "Merge branch"*|"Merge remote"*|"Merge pull request"*) continue ;;
    esac
    SECTIONS[$sec]+="- $bullet"$'\n'
  done < <(git log --pretty=format:'%s%n' "$RANGE" 2>/dev/null)

  for sec in "${ORDER[@]}"; do
    if [[ -n "${SECTIONS[$sec]:-}" ]]; then
      out+="### $sec"$'\n'
      out+="${SECTIONS[$sec]}"$'\n'
    fi
  done
  unset SECTIONS

  prev="$tag"
done

# Footer
out+=$'\n'
out+="## Install"$'\n'$'\n'
out+='```bash'$'\n'
out+="npx -y skills add lora-sys/ai-engineering-harness -g --all"$'\n'
out+='```'$'\n'

out+=$'\n'
out+="## Releases"$'\n'$'\n'
for ((i=${#TAGS[@]}-1; i>=0; i--)); do
  t="${TAGS[$i]}"
  out+="- [$t]: https://github.com/lora-sys/ai-engineering-harness/releases/tag/$t"$'\n'
done

# Output
if [[ $DO_WRITE -eq 1 ]]; then
  printf '%s' "$out" > "$OUTFILE"
  echo "wrote $OUTFILE ($(wc -l < "$OUTFILE") lines)" >&2
else
  printf '%s' "$out"
fi
