# Workflow — New agent from PRD / idea

Trigger: user has a PRD, idea, or "convert this script into an agent."

1. **Run Decision 0** (`references/decision-0.md`). If it fails, stop and tell the user *why* a script is the right answer instead.
2. **Write the Agent Contract** (`templates/agent-contract.md`). Fill every section. Don't leave fields empty.
3. **Write the Harness Spec** (`templates/harness-checklist.md`). Especially: stop condition, eval, human approval.
4. **Pick the framework** if forced to (otherwise `$ai-engineering-harness` will pick): TBD — defer unless user has a constraint.
5. **Run `scripts/scaffold-agent-spec.sh <agent-name>`** to emit `docs/agent-spec/<agent-name>.md`.
6. **Hand off** to `$ai-engineering-harness`:
   ```text
   Use $ai-engineering-harness to bootstrap this repo from docs/agent-spec/<agent-name>.md
   ```
7. Stay in this skill only if the user pushes back ("prompt is unclear", "tool schema is wrong"). Defer everything else.
