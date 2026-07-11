# Context Levels (L0–L3)

The harness partitions every piece of project context into four levels. The `context-assembly` agent decides what each Agent actually loads.

## L0 — Always-on rules

- `AGENTS.md` / `CLAUDE.md` — global rules.
- `CONTRIBUTING.md` / `ENGINEERING.md` high-level rules.
- `PROJECT_STATUS.md` snapshot.
- The harness's own contracts (this skill's `SKILL.md`).
- These are absorbed once at session start and rarely re-read.

## L1 — Task-local context (loaded by context-assembly)

- The Issue body (full).
- Implementation Plan (full).
- The relevant module doc from `docs/architecture/<module>.md` (the section, not the full file).
- The relevant ADR(s).
- The Acceptance Criteria checklist.
- The Evidence dir (read-only during context assembly).

## L2 — Related context (loaded on demand)

- Adjacent module docs.
- Interface contracts (`docs/api/...`).
- Past phase summaries that touch the same module.
- Project-memory + role-memory entries that are recent and on-topic.

## L3 — Deep context (only when explicitly needed)

- Full original spec / PRD sections.
- The complete Evidence pack from earlier issues.
- Historical session logs.
- Raw PDFs / images / long transcripts (extract conclusions, do not load whole files).

## Hard Rules

- **No "load everything"**. The harness refuses to load `docs/`, `memory/`, `sessions/`, or the codebase in bulk. Use the index.
- **No PDF / image load by default**. Extract conclusions.
- **Cite document IDs**. Every load must name the source (path:section or doc ID).
- **Context manifest required**. `agents/context-assembly.md` writes a manifest for every task so reviewers can audit what each Agent saw.

## Choosing a Level

| Need                                                  | Level |
| ----------------------------------------------------- | ----- |
| "What's the project's policy on worktrees?"           | L0    |
| "What's this Issue's Acceptance Criteria?"            | L1    |
| "Where does this module live, what does it import?"   | L1    |
| "Why did we pick Go over Rust for the pipeline?"      | L2    |
| "What was the previous phase's verdict on the same?"  | L2    |
| "What did the original designer intend in this PRD?"  | L3    |
| "Show me the full PDF of the design doc."             | ❌ — extract instead |

