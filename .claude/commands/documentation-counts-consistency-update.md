---
name: documentation-counts-consistency-update
description: Workflow command scaffold for documentation-counts-consistency-update in ai-engineering-harness.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /documentation-counts-consistency-update

Use this workflow when working on **documentation-counts-consistency-update** in `ai-engineering-harness`.

## Goal

Update all documentation files to ensure that referenced counts (e.g., number of workflows, tests, examples) are accurate and consistent across the repo.

## Common Files

- `README.md`
- `README_EN.md`
- `CONTRIBUTING.md`
- `QUICKSTART.md`
- `SKILL.md`
- `meta.json`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Identify all locations in documentation where counts are referenced.
- Update counts in all relevant files to match the actual state of the repo.
- Add or update invisible <!-- count:key --> markers for machine-checking.
- Verify that no count drift remains between files.
- Optionally, update related descriptions or tables to reflect the new numbers.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.