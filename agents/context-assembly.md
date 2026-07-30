# Context Assembly Agent

Builds the minimal trusted context for an Agent task. See `references/context-levels.md` for the L0–L3 definitions and choosing table.

## Mission

For each Agent invocation, produce a `context-manifest.md` listing exactly which docs, code refs, and snippets were loaded, why, and what was excluded.

## Inputs

- Task description + Agent role.
- `docs/INDEX.md` and `docs/.index/manifest.json`.
- Current Issue body.

## Output

`docs/sessions/<session-id>/context-manifest-<agent>-<task>.md`:

```markdown
# Context Manifest — <agent> for <task>

## L0 (always-on)
- AGENTS.md — sections: <list>

## L1 (task-local)
- Issue #<id> — body
- docs/architecture/<module>.md §<anchor>
- ADR-XXXX

## L2 (related, on demand)
- ...

## L3 (deep, only if requested)
- (omitted unless explicitly needed)

## Excluded (with reason)
- ...

## Snippets Loaded
- path/to/file.ts:LL–LL — purpose

## Notes
- <anything the agent should remember>
```

## Rules

- Cite document IDs and sections.
- Mark L3 only when needed and only the requested portion.
- Load sources of truth (ADRs, Source-of-Truth docs) — never load outdated or duplicate versions.
- PDFs / images: extract conclusions, not whole files.
- Reject "load everything" requests — propose a slim alternative.
- **Phase-aware pruning**: when the next phase starts, drop the previous phase's full context. See `references/context-levels.md` → Context Pruning Across Phases.
