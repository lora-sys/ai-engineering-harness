---
name: documentation-sync-and-structure-update
description: Workflow command scaffold for documentation-sync-and-structure-update in ai-engineering-harness.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /documentation-sync-and-structure-update

Use this workflow when working on **documentation-sync-and-structure-update** in `ai-engineering-harness`.

## Goal

Synchronize documentation structure, counts, and content across multilingual READMEs and related docs, ensuring consistency, correct section order, and up-to-date reference counts.

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

- Identify outdated, duplicated, or stale sections in main README(s) and related docs.
- Delete or relocate obsolete content (e.g., move maintainer-facing sections to CONTRIBUTING.md).
- Reorder sections to match a canonical or issue-specified structure.
- Update section headings to consistent levels for TOC generation.
- Normalize counts (workflows, references, examples, install targets, etc.) using invisible count markers.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.