# Context Levels (L0–L3)

The harness partitions every piece of project context into four levels. The `context-assembly` agent decides what each Agent actually loads.

## Choosing a Level

| Need | Level | Example |
|------|-------|---------|
| "What's the project's policy on X?" | **L0** | Worktree rules, secrets policy |
| "What's this Issue's Acceptance Criteria?" | **L1** | Full Issue body + relevant ADRs |
| "Where does this module live, what does it import?" | **L1** | Module doc §relevant-section only |
| "Why did we pick Go over Rust?" | **L2** | ADR entry, not full ADR |
| "What was the previous verdict on this?" | **L2** | Phase summary snippet |
| "What did the original designer intend?" | **L3** | Relevant PRD section only |
| "Show me the full design doc PDF" | ❌ | Extract conclusions, don't load whole file |

## Level Definitions

**L0 — Always-on (loaded once at session start, rarely re-read)**
- `SKILL.md` — this skill's own contract
- `AGENTS.md` / `CLAUDE.md` — global rules, forbidden actions, secrets policy
- `PROJECT_STATUS.md` — current kanban snapshot
- `CONTRIBUTING.md` — high-level workflow rules
- `ENGINEERING.md` — high-level stack rules

**L1 — Task-local (per Issue, assembled by `context-assembly`)**
- Issue body (full)
- Implementation Plan (full)
- Relevant `docs/architecture/<module>.md` — specific sections, not the whole file
- In-scope ADRs
- Acceptance Criteria checklist
- Evidence dir (read-only during assembly)

**L2 — On demand**
- Adjacent module docs (when the task touches them)
- Interface contracts (`docs/api/...`)
- Past phase summaries for the same module
- Relevant `memory/*.md` entries (recent + on-topic only)

**L3 — Explicit only (never by default)**
- Full original spec / PRD sections
- Complete Evidence packs from earlier issues
- Historical session logs
- Raw PDFs / images / long transcripts (extract conclusions)

## Hard Rules

- **No "load everything"**. The harness refuses to bulk-load `docs/`, `memory/`, `sessions/`, or the codebase.
- **No PDF / image load by default**. Extract conclusions.
- **Cite document IDs**. Every load must name the source (path:section or doc ID).
- **Context manifest required**. `agents/context-assembly.md` writes a manifest for every task.
- **Cross-phase pruning**. When moving from Plan → Implement → Review → Merge, drop each phase's full context and carry forward only the manifest + L0. Do not accumulate context across phases.

## Context Pruning Across Phases

```
Phase 1 (Plan)     → full L0+L1 loaded
Phase 2 (Implement)→ L0 + Issue + Plan summary (drop full L1)
Phase 3 (Review)   → L0 + diff + manifest (drop implementation context)
Phase 4 (Merge)    → L0 + Evidence gate checklist only
```

Each phase's Agent gets only what it needs. The previous phase's implementation details are in Evidence, not in the next Agent's context.
