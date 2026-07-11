# Context Manifest

Per Agent-task. Saved as `docs/sessions/<session-id>/context-manifest-<agent>-<task>.md`. See `agents/context-assembly.md`.

```markdown
# Context Manifest — <agent> for <task>

## L0 (always-on rules)
- AGENTS.md — sections: <list>
- ENGINEERING.md — sections: <list>
- CONTRIBUTING.md — sections: <list>

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

