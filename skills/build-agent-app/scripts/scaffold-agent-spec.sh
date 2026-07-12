#!/usr/bin/env bash
# Make a docs/agent-spec/<name>.md scaffold compatible with $ai-engineering-harness.
# Usage: scripts/scaffold-agent-spec.sh <name>
set -euo pipefail

NAME="${1:-unnamed-agent}"
ROOT="${ROOT:-.}"
TARGET="${ROOT}/docs/agent-spec/${NAME}.md"

mkdir -p "$(dirname "$TARGET")"

# Inner heredoc is fully quoted so no shell interpolation. We then sed the
# placeholder into the name. This avoids both shell backticks AND Python
# .format() curly-brace ambiguity.
cat > "$TARGET" <<'BODY'
# NAME_PLACEHOLDER - Agent Spec

> Hand-off document for $ai-engineering-harness.
> Produced by $build-agent-app.

## Role
<!-- one sentence -->

## Goal
<!-- user-observable outcome -->

## Non-goals
<!-- what the agent will NOT do -->

## Inputs
```yaml
shape: {}
example: {}
```

## Outputs
```yaml
shape: {}
example: {}
```

## Tools
<!-- one block per tool, with name + description + input/output schemas -->

## Constraints
<!-- token budget, format rules, forbidden actions -->

## Stop condition
<!-- how the agent knows it is done -->

## Harness spec
<!-- point to templates/harness-checklist.md, or inline the answers -->

## Eval
<!-- per-task and per-capability checks -->

## Approval gate
<!-- list high-risk actions that pause for human -->

## Open questions
<!-- anything the user has not answered yet -->
BODY
sed -i "s/NAME_PLACEHOLDER/${NAME}/g" "$TARGET"
echo "wrote: $TARGET"
