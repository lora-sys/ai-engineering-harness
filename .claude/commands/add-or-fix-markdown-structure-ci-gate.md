---
name: add-or-fix-markdown-structure-ci-gate
description: Workflow command scaffold for add-or-fix-markdown-structure-ci-gate in ai-engineering-harness.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-fix-markdown-structure-ci-gate

Use this workflow when working on **add-or-fix-markdown-structure-ci-gate** in `ai-engineering-harness`.

## Goal

Add or update a CI script to check markdown structure (fence parity, heading levels, count markers) and prevent structural documentation errors from shipping.

## Common Files

- `scripts/check-templates.sh`
- `tests/check-templates.bats`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Create or update a shell script (e.g., scripts/check-templates.sh) to check for fence parity, heading levels inside fences, and invisible count markers.
- Add or update bats tests to cover new rules or edge cases.
- Integrate the script into CI (e.g., test.yml static job).
- Test the script by running it on current and previous versions of the docs to ensure it catches real issues and avoids false positives.
- Document the new checks and ensure contributors are aware of the gate.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.