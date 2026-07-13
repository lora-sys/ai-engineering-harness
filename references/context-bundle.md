# Context Bundle Pattern

A one-shot, parallelized "what does the LLM need to know about this repo" dump that replaces per-sub-agent exploration.

## What it does

`scripts/context-bundle.sh` produces a single markdown file (`context-bundle.md` by default) containing:

| Section | Source |
| --- | --- |
| Repo identity | `git remote get-url`, `git branch`, `git describe` |
| Recent commits | `git log -n N --oneline` |
| Working-tree changes | `git status`, `git diff --stat`, untracked files |
| Top-level layout | `ls -la` + harness subdir counts |
| Open issues & PRs | `gh` CLI (silent skip if unauth) |
| Key harness files | CLAUDE.md / AGENTS.md / SKILL.md / etc., with line counts |
| Memory notes | last 3 files in `memory/*.md`, head 60 lines each |
| Harness roster | workflows, agents, templates |

Sections run in parallel (each as a backgrounded subshell), so wall time is `max(section_times)` rather than `sum(section_times)`.

## Why it matters

Without this, every sub-agent runs its own `git log`, `ls`, `find`, etc. before it can act. That's:

- **Slow**: 5–10 redundant slow commands per agent × N agents.
- **Drifty**: each agent sees a slightly different snapshot.
- **Noisy**: chat history gets cluttered with exploration transcripts.

With this, the Coordinator dumps the bundle once (5–8 s), references it from `docs/evidence/<id>/context-bundle.md`, and sub-agents read that file instead of exploring.

## Usage

```bash
# Default: writes ./context-bundle.md, 20 recent commits, parallel
scripts/context-bundle.sh

# Custom output path (typical for evidence pack)
scripts/context-bundle.sh --out docs/evidence/42/context-bundle.md

# Deeper history
scripts/context-bundle.sh --commits 50

# Sequential (debugging only — sections run one at a time)
scripts/context-bundle.sh --no-parallel

# Quiet (no progress to stderr)
scripts/context-bundle.sh --quiet
```

## Where it goes in the harness

`workflows/01-feature-delivery.md` Phase 4 (Plan) calls `scripts/context-bundle.sh` once, writes the bundle to `docs/evidence/<id>/context-bundle.md`, and references it from the Implementation Plan. Sub-agents spawned in Phase 5+ read that file (already in their context manifest) instead of re-exploring.

## Reproducibility

The bundle is a pure function of `git` state + `gh` CLI state at the moment it runs. Two runs minutes apart produce near-identical output (only the timestamp and any new commits differ). Reviewers can diff two bundles to see "what changed between plan and implement".

## Failure modes

| Failure | Behaviour |
| --- | --- |
| `gh` CLI not installed | Open issues & PRs section says "(gh CLI not installed; skipping)" |
| `gh` not authenticated | "(gh CLI present but not authenticated; skipping)" |
| `gh issue list` itself fails | "[error: gh issue list failed]" — bundle still written |
| Not a git repo | Repo identity section missing; rest of bundle still produced |
| Working tree clean | "Working-tree changes" section shows "(clean)" |

The script **always writes the bundle** unless it can't reach the repo root. Failed sections get `[error: ...]` markers so reviewers can see what didn't work.

## See also

- `scripts/context-manifest.sh` (planned) — assembles the L0–L3 context manifest that references the bundle.
- `agents/context-assembly.md` — the agent that decides which slices of the bundle each sub-agent sees.
- `templates/context-manifest.md` — the manifest template.
