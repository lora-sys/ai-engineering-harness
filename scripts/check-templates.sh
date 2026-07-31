#!/usr/bin/env bash
# scripts/check-templates.sh — assert that required sections exist in harness templates,
# and that every tracked markdown file is structurally sound.
#
# Why (part 1 — template assertions): a previous maintainer pass claimed to add
# "## CI" to templates/pr-description.md and walked away. `git diff` later showed
# the edit never landed. This script makes those required sections *enforced* — a
# missing required heading fails the check loudly, so the regression can't repeat
# silently.
#
# Why (part 2 — markdown structure): README.md shipped with a splice that left an
# unfenced shell block and an orphaned ``` behind. The total fence count stayed
# even, so parity checks passed, but fence *pairing* inverted for 248 lines — 28%
# of the file rendered as the opposite of what it was. An entire section rendered
# as a code block, and an image never rendered once. Nothing in CI looked at
# markdown at all, which is why it shipped.
#
# The rule that actually catches this shape was picked by measurement, not guess:
#   - fence-count parity          → caught nothing (68 fences, even)
#   - any ^#{1,6} inside a fence  → 26 false-positive files (every `# comment`
#                                   inside a ```bash block matches)
#   - ^#{2,6} inside a NON-markdown fence → hit only the corrupted file, 31 times,
#                                   zero false positives repo-wide
# So the primary signal is "a ##+ heading inside a fence that isn't quoting
# markdown". Fences opened as ```markdown / ```md / ```mdx are exempt, because
# templates legitimately quote markdown inside them.
#
# Why (part 3 — count drift): the same README claimed 9 workflows (10), 6
# references (11), 6 examples (7) and 38 install targets (40) — on a page whose
# own table listed 40 rows. Numbers marked with an invisible <!-- count:key -->
# comment are checked against the filesystem. Test counts are deliberately NOT
# guarded: they change on every test commit, which would make this noise.
#
# Usage:
#   scripts/check-templates.sh           # check all templates + markdown structure
#   scripts/check-templates.sh --strict  # also fail on soft warnings
#
# Add new assertions by appending to the TEMPLATE_ASSERTIONS array below.
#
# bash 3.2 compatible (macOS /bin/bash): no mapfile, no declare -A, no process
# substitution, no heredoc inside $( ).

set -uo pipefail
# Resolve script location and cd to repo root (parent of scripts/).
# This makes the script work no matter where it's invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

STRICT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help)
      sed -n 2,40p "$0"
      exit 0
      ;;
  esac
done

# Required headings per template. Format: "template-file|required-heading|severity"
#   severity = "error"   → fails the script with non-zero exit
#   severity = "warning" → prints warning; only fails in --strict
TEMPLATE_ASSERTIONS=(
  "templates/pr-description.md|## CI|error"
  "templates/pr-description.md|## Risk|error"
  "templates/pr-description.md|## Rollback Plan|error"
  "templates/pr-description.md|## Evidence|error"
  "templates/pr-description.md|## Checklist|error"
  "templates/evidence-pack.md|## How Verified|error"
  "templates/evidence-pack.md|## change-summary.md|error"
  "templates/implementation-plan.md|## Acceptance Criteria|error"
  "templates/review-report.md|## Findings|error"
  "templates/issue.md|## Acceptance Criteria|error"
  "templates/issue-bug.md|## Reproduction|error"
  "templates/issue-bug.md|## Expected|error"
  "templates/adr.md|## Decision|error"
  "templates/adr.md|## Consequences|error"
  "templates/phase-summary.md|## Shipped (PRs)|error"
)

errors=0
warnings=0
checked=0
for row in "${TEMPLATE_ASSERTIONS[@]}"; do
  IFS='|' read -r file heading severity <<< "$row"
  checked=$((checked + 1))
  if [[ ! -f "$file" ]]; then
    echo "ERROR  template missing: $file"
    errors=$((errors + 1))
    continue
  fi
  if ! awk -v h="$heading" 'index($0, h) == 1 {found=1; exit} END{exit !found}' "$file"; then
    if [[ "$severity" == "error" ]]; then
      echo "ERROR  $file  missing required heading: $heading"
      errors=$((errors + 1))
    else
      echo "WARN   $file  missing soft-required heading: $heading"
      warnings=$((warnings + 1))
    fi
  fi
done

# ---------------------------------------------------------------------------
# Part B — markdown structure: fence pairing, headings trapped in code blocks
# ---------------------------------------------------------------------------
# One awk pass per file emits "SEV|LINE|MSG" lines; the shell just counts them.
# Paths with spaces: none are tracked today. If that changes, switch the loop to
# `git ls-files -z` + `while IFS= read -r -d ''`.

MD_STRUCTURE_AWK='
  /^[ \t]*(```|~~~)/ {
    if (!infence) {
      infence = 1; open_line = NR
      # Exempt fences that quote markdown — a ## inside ```markdown is content.
      tag = $0
      sub(/^[ \t]*(```|~~~)[ \t]*/, "", tag)
      sub(/[ \t].*$/, "", tag)
      exempt = (tolower(tag) == "markdown" || tolower(tag) == "md" || tolower(tag) == "mdx")
    } else {
      infence = 0; exempt = 0
    }
    next
  }
  infence && !exempt {
    if ($0 ~ /^#{2,6} /) {
      print "ERROR|" NR "|heading inside a code fence (opened line " open_line ") — renders as code, not a heading"
    } else if ($0 ~ /^!\[/) {
      print "WARN|" NR "|image inside a code fence (opened line " open_line ") — will not render"
    } else if ($0 ~ /^\|.*\|[ \t]*$/) {
      print "WARN|" NR "|table row inside a code fence (opened line " open_line ") — will not render"
    }
  }
  END {
    if (infence) print "ERROR|" open_line "|code fence opened here is never closed"
  }
'

md_files=0
for f in $(git ls-files '*.md' 2>/dev/null); do
  case "$f" in
    docs/evidence/*|sessions/*|*/node_modules/*|*/.dashboard/*) continue ;;
  esac
  [[ -f "$f" ]] || continue
  md_files=$((md_files + 1))
  shown=0
  while IFS='|' read -r sev line msg; do
    [[ -z "$sev" ]] && continue
    if [[ "$sev" == "ERROR" ]]; then
      errors=$((errors + 1))
    else
      warnings=$((warnings + 1))
    fi
    shown=$((shown + 1))
    if [[ $shown -le 3 ]]; then
      printf '%-6s %s:%s  %s\n' "$sev" "$f" "$line" "$msg"
    elif [[ $shown -eq 4 ]]; then
      echo "       $f  … more findings in this file suppressed"
    fi
  done <<< "$(awk "$MD_STRUCTURE_AWK" "$f")"
done

# ---------------------------------------------------------------------------
# Part C — count drift: <!-- count:key --> markers vs the filesystem
# ---------------------------------------------------------------------------
# A marked line's first integer must equal the real directory count. This is the
# other half of what let issue #11 happen: the README claimed 9 workflows, 6
# references, 6 examples and 38 install targets, all wrong, for months.
#
# Test counts are intentionally absent — they change on every test commit, and a
# gate that fires on routine work gets disabled instead of obeyed.
COUNT_KEYS="agents workflows templates checklists references examples skills"

real_count() {
  case "$1" in
    agents)     ls -1 agents/*.md 2>/dev/null | wc -l ;;
    workflows)  ls -1 workflows/*.md 2>/dev/null | wc -l ;;
    templates)  ls -1 templates/*.md 2>/dev/null | wc -l ;;
    checklists) ls -1 checklists/*.md 2>/dev/null | wc -l ;;
    references) ls -1 references/*.md 2>/dev/null | wc -l ;;
    examples)   ls -1 examples 2>/dev/null | wc -l ;;
    skills)     ls -1d skills/*/ 2>/dev/null | wc -l ;;
  esac
}

for doc in README.md README_EN.md; do
  [[ -f "$doc" ]] || continue
  for key in $COUNT_KEYS; do
    marked="$(grep -n "count:$key" "$doc" 2>/dev/null | head -1 || true)"
    if [[ -z "$marked" ]]; then
      echo "WARN   $doc  no <!-- count:$key --> marker — that number is unguarded"
      warnings=$((warnings + 1))
      continue
    fi
    lineno="${marked%%:*}"
    claimed="$(printf '%s' "$marked" | sed 's/^[0-9]*://' | grep -o '[0-9][0-9]*' | head -1)"
    actual="$(real_count "$key" | tr -d ' ')"
    if [[ "$claimed" != "$actual" ]]; then
      echo "ERROR  $doc:$lineno  count:$key says $claimed, filesystem has $actual"
      errors=$((errors + 1))
    fi
  done
done

# install.sh's target list is not a glob count, and the README got it wrong in
# three separate places, so it gets its own assertion.
if [[ -f install.sh ]]; then
  targets="$(awk '/^TARGETS=\(/{f=1;next} f&&/^\)/{exit} f&&NF{c++} END{print c+0}' install.sh)"
  for doc in README.md README_EN.md; do
    [[ -f "$doc" ]] || continue
    if ! grep -q "$targets" "$doc" 2>/dev/null; then
      echo "WARN   $doc  never mentions the real install.sh target count ($targets)"
      warnings=$((warnings + 1))
    fi
  done
fi

echo
echo "Checked: $checked assertions  ·  $md_files markdown files  ·  Errors: $errors  ·  Warnings: $warnings"
if [[ $errors -gt 0 ]]; then
  echo "FAIL  template structure incomplete"
  exit 1
fi
if [[ $STRICT -eq 1 && $warnings -gt 0 ]]; then
  echo "FAIL  --strict: $warnings warning(s) present"
  exit 1
fi
echo "OK    template structure passes"
