#!/usr/bin/env bash
# scripts/check-templates.sh — assert that required sections exist in harness templates.
#
# Why: a previous maintainer pass claimed to add "## CI" to templates/pr-description.md
# and walked away. `git diff` later showed the edit never landed. This script makes
# those required sections *enforced* — a missing required heading fails the check
# loudly, so the regression can't repeat silently.
#
# Usage:
#   scripts/check-templates.sh           # check all templates
#   scripts/check-templates.sh --strict  # also fail on soft warnings
#
# Add new assertions by appending to the TEMPLATE_ASSERTIONS array below.

set -uo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

STRICT=0
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    -h|--help)
      sed -n 2,18p "$0"
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

echo
echo "Checked: $checked assertions  ·  Errors: $errors  ·  Warnings: $warnings"
if [[ $errors -gt 0 ]]; then
  echo "FAIL  template structure incomplete"
  exit 1
fi
if [[ $STRICT -eq 1 && $warnings -gt 0 ]]; then
  echo "FAIL  --strict: $warnings warning(s) present"
  exit 1
fi
echo "OK    template structure passes"
