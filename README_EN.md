# AI Engineering Harness

> **From "it kinda works" to verified.**
>
> A software-engineering organization of AI agents that turns vibe-coded repos into verifiable, reviewable, shippable code.

<p align="left">
  <a href="#one-line-install--every-cli-agent-globally"><img alt="install" src="https://img.shields.io/badge/install-npx%20skills%20add%20lora--sys%2Fai--engineering--harness-111"></a>
  <a href="./LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-blue"></a>
  <a href="https://github.com/lora-sys/ai-engineering-harness"><img alt="stars" src="https://img.shields.io/badge/stars-%E2%AD%90%EF%B8%8F-yellow"></a>
</p>

![Architecture · AI Engineering Harness](./assets/architecture.svg)

## Positioning

### Do you have a repo like this?

AI wrote 2,000 lines of code. It runs. But you're afraid to touch it. No tests. No CI. No docs. You know something is wrong, but you don't know where to start.

**That's what Harness solves.**

`ai-engineering-harness` is **a software-engineering organization**, not a coding prompt. Hand it a mess, and it spins up an 18-role AI engineering team that walks a full closed loop:

```
Idea → PRD → Issue → Agent claims → Worktree → Plan → Implement
     → Self-test → Draft PR → CI → Adversarial Review → Fix → Re-review
     → Evidence Gate → Human Approval (when needed) → Merge
     → Phase summary → Memory update → next Issue
```

Code only reaches `main` when **CI is green**, **≥2 cold-start reviewers approve**, and **Evidence is complete**. There is no "it kinda works". There is only **verified** working.

## What's inside

### 3 Capabilities + 1 Observability Panel

This repo is a **skill family** — installable separately or together:

| Skill | Capability | One-liner |
|-------|-----------|-----------|
| **`$ai-engineering-harness`** | Engineering takeover & closed-loop delivery | Full-stack engineering org from Issue to Merge |
| **`$build-agent-app`** | Agent app design & contracts | Design an AI agent app, hand off to harness for implementation |
| **`$frontend-creative`** | Awwwards-grade creative frontend | Generate award-winning Web UIs with AI |
| **`$dashboard`** | _Optional · observability panel_ | Quick Scan + kanban, scaffolded into a project and auto-started |

The first three are **delivery** capabilities you invoke to produce work. `dashboard`
is different: it gets scaffolded into a project (`.dashboard/` + `localhost:4321`)
and only activates once that directory exists.

> AI can write fast. Engineering discipline makes it ship.

> **中文版本**: [README.md](README.md) · **English version**: you are here

## How it works

#### Required Issue fields

Context / Goal / Scope / Non-Goal / Related Docs / Implementation Plan / Acceptance Criteria / Evidence Requirements / Reviewer Requirements / Owner / Estimate. The Coordinator refuses to start coding on an Issue missing any field.

#### L0–L3 context control

- **L0** — always-on rules (sketch of `AGENTS.md`, `ENGINEERING.md`, `CONTRIBUTING.md`)
- **L1** — task-local (Issue body, relevant module doc, ADR, ACs)
- **L2** — adjacent modules, recent phase summaries, interface contracts
- **L3** — deep context (only on explicit request); PDFs / images / long reports must be summarized, not loaded whole

`agents/context-assembly.md` produces a `context-manifest.md` for every task, so reviewers can audit what each Agent saw.

#### Evidence Gate

"Done" means `docs/evidence/<id>/` contains:

- `change-summary.md`, `verification.md` (PASS/FAIL per AC)
- Frontend: 6-state screenshots (desktop/tablet/mobile/empty/error/loading) + Playwright trace + console clean + a11y scan
- Backend: API trace, exception coverage, auth negative cases, perf baseline
- Database: migration + rollback, pre/post stats, sample rows
- Reviewers: `review-<role>.md` × ≥ 2 + `fix-tasks.md` Aggregator ✅
- CI: green, no Critical/High blocker

#### Human Approval Gate

Triggered for: auth/authz model · DB schema with data migration · production secrets or paid APIs · release/version. The Coordinator posts a `Waiting for Approval` note on `PROJECT_STATUS.md` and pauses.

#### File-system message bus

Each Session has `sessions/<id>/{status,plan,execution,review,summary}.md`. Agents coordinate through files, not chat. New Sessions read `memory/` + the last `summary.md` to resume.

### When NOT to use this skill

- One-file throwaway edits
- Prototypes you don't intend to keep
- You want to write the code yourself

### Repository layout

| Directory | Count | What it holds |
|-----------|------:|---------------|
| [`agents/`](./agents/) | 18 <!-- count:agents --> | Agent personas |
| [`workflows/`](./workflows/) | 10 <!-- count:workflows --> | Closed-loop procedures (incl. `09-pr-intake.md`) |
| [`templates/`](./templates/) | 16 <!-- count:templates --> | Issue / Plan / PR / Review / Evidence / Phase / ADR |
| [`checklists/`](./checklists/) | 6 <!-- count:checklists --> | Acceptance checklists |
| [`references/`](./references/) | 11 <!-- count:references --> | Deep-dive docs (L0–L3, indexing, worktree, spawning, CI, sessions) |
| [`examples/`](./examples/) | 7 <!-- count:examples --> | Filled samples |
| [`skills/`](./skills/) | 3 <!-- count:skills --> | Sibling skills (`build-agent-app` / `frontend-creative` / `dashboard`) |
| [`tests/`](./tests/) | — | bats regression suite |
| [`hooks/`](./hooks/) | — | Claude Code SessionStart hook |
| [`scripts/`](./scripts/) | — | Maintenance scripts, see [CONTRIBUTING.md](./CONTRIBUTING.md) |

Entry points are [`SKILL.md`](./SKILL.md) (the first file every Agent loads) and
[`install.sh`](./install.sh) (40 CLI-agent targets).

## Installation

### One-line install — every CLI agent, globally

```bash
npx -y skills add lora-sys/ai-engineering-harness -g --all --full-depth
```

- `-g` → global install
- `--all` → installs to every supported CLI agent
- `--full-depth` → discovers all skills in subdirectories (build-agent-app, frontend-creative, dashboard)

#### Scoped install

```bash
# Preview before installing
npx -y skills add lora-sys/ai-engineering-harness --list

# One skill only
npx -y skills add lora-sys/ai-engineering-harness -g -s ai-engineering-harness

# Specific agents only
npx -y skills add lora-sys/ai-engineering-harness -g -a claude-code codex grok
```

Compatible with 40+ CLI agents: Claude Code, Codex, Grok, Cursor, Gemini, Qwen, Cline, Hermes-Agent, Continue, Devin, Roo, Tabnine, Trae, Warp, Windsurf, Zed and more.

#### Manual install — more control

```bash
git clone https://github.com/lora-sys/ai-engineering-harness.git
cd ai-engineering-harness

# Interactive
./install.sh

# Specific target
./install.sh --target claude
./install.sh --target cursor

# Every writable location
./install.sh --all
```

`install.sh` supports 40 targets. Full list: `codex`, `claude`, `agents`, `cursor`, `gemini`, `qwen`, `opencode`, `grok`, `hermes-agent`, `hermes`, `aider-desk`, `augment`, `bob`, `codebuddy`, `commandcode`, `continue`, `crush`, `devin`, `factory`, `forge`, `goose`, `iflow`, `junie`, `kilocode`, `kiro`, `kode`, `marscode`, `mux`, `neovate`, `openhands`, `pi`, `pochi`, `roo`, `snowflake`, `tabnine`, `trae`, `trae-cn`, `vibe`, `zencoder`, `adal`.

#### Bulk-install the whole family (recommended)

```bash
# Thin install (SKILL.md + meta.json only)
bash scripts/install-all-skills.sh

# Fat install (full bundle — workflows/, references/, templates/)
bash scripts/install-all-skills.sh --fat

# Status check across 14 targets
bash scripts/install-all-skills.sh --status
```

## Compatible CLI agents

`install.sh` supports 40 targets, covering Claude Code, Codex, Cursor, Gemini,
Qwen, Grok, OpenCode, Continue, Roo, Tabnine, Trae, Zed and more. Full list with
install paths below, or read [`install.sh`](./install.sh) directly.

<details>
<summary><b>40 targets and their install paths (click to expand)</b></summary>

| Compatibility / 兼容性 | Install path / 安装路径 | Status after one-liner / 一行安装后状态 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | ✅ |
| Codex | `~/.codex/skills/` | ✅ |
| Cursor | `~/.cursor/skills/` | ✅ |
| Gemini CLI | `~/.gemini/skills/` | ✅ |
| Qwen / Qoder | `~/.qwen/skills/` | ✅ |
| Grok CLI | `~/.grok/skills/` | ✅ |
| OpenCode | `~/.config/opencode/skills/` | ✅ |
| Hermes-Agent | `~/.hermes/hermes-agent/skills/` | ✅ |
| Hermes | `~/.hermes/skills/` | ✅ |
| Aider Desk | `~/.aider-desk/skills/` | ✅ |
| Augment | `~/.augment/skills/` | ✅ |
| Bob | `~/.bob/skills/` | ✅ |
| Codebuddy | `~/.codebuddy/skills/` | ✅ |
| Commandcode | `~/.commandcode/skills/` | ✅ |
| Continue | `~/.continue/skills/` | ✅ |
| Crush | `~/.config/crush/skills/` | ✅ |
| Devin | `~/.config/devin/skills/` | ✅ |
| Factory | `~/.factory/skills/` | ✅ |
| Forge | `~/.forge/skills/` | ✅ |
| Goose | `~/.config/goose/skills/` | ✅ |
| iFlow | `~/.iflow/skills/` | ✅ |
| Junie | `~/.junie/skills/` | ✅ |
| KiloCode | `~/.kilocode/skills/` | ✅ |
| Kiro | `~/.kiro/skills/` | ✅ |
| Kode | `~/.kode/skills/` | ✅ |
| Marscode | `~/.marscode/skills/` | ✅ |
| Mux | `~/.mux/skills/` | ✅ |
| Neovate | `~/.neovate/skills/` | ✅ |
| OpenHands | `~/.openhands/skills/` | ✅ |
| Pi | `~/.pi/agent/skills/` | ✅ |
| Pochi | `~/.pochi/skills/` | ✅ |
| Roo | `~/.roo/skills/` | ✅ |
| Snowflake Cortex | `~/.snowflake/cortex/skills/` | ✅ |
| Tabnine | `~/.tabnine/skills/` | ✅ |
| Trae | `~/.trae/skills/` | ✅ |
| Trae-CN | `~/.trae-cn/skills/` | ✅ |
| Vibe | `~/.vibe/skills/` | ✅ |
| Zencoder | `~/.zencoder/skills/` | ✅ |
| Adal | `~/.adal/skills/` | ✅ |
| `.agents/` (unified) | `~/.agents/skills/` | ⏳ pending OS-level mount-RW on this system |
---

</details>

## Use cases

### Typical usage

#### 1. Start a brand-new project from a PRD

```
Use $ai-engineering-harness to bootstrap this repo from PRD.md.
```

The bootstrap workflow (`workflows/00-project-bootstrap.md`) will create `docs/`, `memory/`, `PROJECT_STATUS.md`, Issue / PR templates, CI configs, ADR / phase-summary templates, and a seed set of Issues.

#### 2. Resume or audit an existing project

```
Use $ai-engineering-harness. Read PROJECT_STATUS.md and continue the next Todo.
```

```
Use $ai-engineering-harness to audit this repo: list open PRs older than 7 days,
flag missing Evidence, and produce a recovery plan.
```

#### 3. Take one Issue to merged

```
Use $ai-engineering-harness to take Issue #17 from Planning to Done.
```

That walks: write Plan → spawn Frontend/Backend/Database on Worktrees → implement → self-test → Draft PR → CI → adversarial review → fix loop → Evidence Gate → merge → phase summary → memory write.

## Usage Guide

> This section makes "how to actually use it" concrete. Read the 4 high-frequency
> invocations first, then the operating principles, then advanced usage and anti-patterns.

### Top 4 invocations

#### ① Bootstrap a new project from a PRD

```
Use $ai-engineering-harness to bootstrap this repo from PRD.md.
```

The Coordinator follows `workflows/00-project-bootstrap.md` and creates, in one pass:
`docs/{product,architecture,design,decisions}`, `memory/`, `PROJECT_STATUS.md`,
`AGENTS.md` / `CLAUDE.md`, `DESIGN.md`, `ENGINEERING.md`, `TESTING.md`,
`CONTRIBUTING.md`, `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`,
the phase-summary template, and the first round of Issues.

#### ② Resume interrupted work

```
Use $ai-engineering-harness. Read PROJECT_STATUS.md and continue the next Todo.
```

Reads `memory/` plus the previous Session's `summary.md` and picks up where it stopped.

#### ③ Take one Issue to merged

```
Use $ai-engineering-harness to take Issue #17 from Planning to Done.
```

Walks the full closed loop: write the Plan → dispatch Frontend/Backend/Database
Agents on isolated Worktrees → Implement → Self-test → Draft PR → CI → cold-start
adversarial review (Bug Hunter + Behavior Reviewer, plus Architecture/Security/UI
when warranted) → Fix loop → Evidence Gate → Merge → Phase summary → Memory write.

#### ④ Audit or rescue

```
Use $ai-engineering-harness to audit this repo: list open PRs older than 7 days,
flag missing Evidence, and produce a recovery plan.
```

It inventories the gap from "current" to "expected", turns it into a batch of
auto-triaged Issues, and names the first three actions in the order to do them.

### Operating principles

| # | Principle | Why |
|---|---|---|
| 1 | **Trust evidence, not vibes** | The Coordinator will not merge because "it passed locally". It needs every AC line in `docs/evidence/<id>/verification.md` marked PASS, CI green, ≥ 2 reviewers ✅, and the Aggregator ✅. Missing one → not Done. |
| 2 | **Cold-start reviews** | A Reviewer reads only Issue + Plan + PR diff + Evidence — **never the implementer's chat or explanation**. This is what prevents talking yourself into it. |
| 3 | **Issues are the unit of work** | No Issue, no work. An Issue must carry Context / Goal / Scope / Non-Goal / Related Docs / Plan / AC / Evidence Reqs / Reviewer Reqs / Owner / Estimate. |
| 4 | **Worktree isolation** | One Issue = one Owner = one Worktree = one branch. Parallel Owners never interfere; they meet only in the Conflict Resolver. |
| 5 | **L0–L3 context control** | `docs/` is not loaded whole by default. `agents/context-assembly.md` emits a per-task `context-manifest.md` carrying the minimum trusted context that task needs. |
| 6 | **Human Approval Gate** | For auth / database schema / production secrets / paid APIs / release versions, the Coordinator calls `request_user_input` and stops. It does not make those calls for you. |
| 7 | **Memory is project state, not chat** | Stable conclusions go to `docs/` and `memory/`; chat history is not retained. After each Phase the Coordinator runs `workflows/06-phase-summary.md`. |
| 8 | **CI/CD is a blocking gate, not a checklist item** | The Owner watches CI from the first commit; the Coordinator blocks Phase 8 / merge / Done until it is green. Red CI ⇒ `workflows/04-ci-recovery.md`; the same class of failure twice ⇒ a `ci`-tagged Issue + one line in `memory/lessons.md`. See `references/cd-monitoring.md`. |
| 9 | **Local-first** | When a PR proposes code that already has a local equivalent, **do not merge it**: comment with the local paths and let the author align with the local version or propose something genuinely incremental. The local version stays. See `workflows/09-pr-intake.md` Step 2. |

### Canonical invocations

```text
# Bootstrap
Use $ai-engineering-harness to bootstrap this repo from PRD.md.

# Resume
Use $ai-engineering-harness. Read PROJECT_STATUS.md and continue the next Todo.

# Drive a single Issue
Use $ai-engineering-harness to take Issue #17 from Planning to Done.

# Audit / rescue
Use $ai-engineering-harness to audit this repo and produce a recovery plan.

# Hand off across CLIs (Claude → Grok: chat history is useless, on-disk state is not)
Use $ai-engineering-harness. I'm continuing from another agent. Read
memory/project-memory.md and sessions/<last-id>/summary.md, then continue.

# Read one phase summary without opening all of docs/
Use $ai-engineering-harness. Summarize the latest phase.

# Dispatch several Issues to frontend / backend / database Agents in parallel
Use $ai-engineering-harness to spawn parallel Owners for Issue #20, #21, #22.
```

### Advanced usage

#### Stand up a new project in 30 seconds

```bash
mkdir my-saas && cd my-saas
git init
echo "# My SaaS" > README.md
git add . && git commit -m "feat: init"

# Then, in any CLI (Codex / Claude / Grok / Cursor / Gemini ...):
# Use $ai-engineering-harness to bootstrap this repo from PRD.md
```

The Coordinator generates the directory skeleton, the first round of Issues, the ADR
template and a CI workflow placeholder, then writes "Phase 0 / Bootstrap — Done" to
`PROJECT_STATUS.md`.

#### Take over an old project and backfill the engineering basics

```
Use $ai-engineering-harness to take over this repo. Inventory the gap
between current state and harness layout; file Issues for the missing
pieces; do not edit code yet.
```

It inventories first, files the gaps as Issues, then works through them;
**it does not touch business code up front**.

#### Hand off across CLIs

All harness state is on disk, so **nothing is lost with the chat history**.
Switching from Claude to Grok:

```
Use $ai-engineering-harness. I'm continuing from another agent. Read
memory/project-memory.md and the latest sessions/<id>/summary.md.
```

#### Run several things in parallel

```
Use $ai-engineering-harness to plan and dispatch Issue #18 (frontend),
#19 (backend), #20 (database) in parallel Worktrees.
```

The Coordinator creates three Worktrees — `feature/18-...`, `feature/19-...`,
`feature/20-...` — and each Owner drives its own PR. Conflicts go to the Conflict
Resolver; **nothing is overwritten automatically**.

#### Let it heal a red CI

```
CI is red on PR #N. Use $ai-engineering-harness to recover.
```

Runs `workflows/04-ci-recovery.md`: classify in 60 seconds (flaky / real defect /
lint / integration / infra) → dispatch an Owner Agent to fix → re-run CI → back
through the Reviewers.

### Anti-patterns

| Anti-pattern | Why it fails | Do this instead |
|---|---|---|
| "Just start on it" with an Issue missing fields | The Coordinator won't start. | Fill the fields in (the template is in `.github/ISSUE_TEMPLATE/`). |
| Committing straight to `main` / `master` | Refused. Worktrees are a hard requirement. | `git worktree add ../proj-issue-<id> -b feature/<id>-<slug> main` |
| Letting the implementer "self-review" | Reviewers **must** cold-start. | Have it spawn an independent Reviewer Agent fed only Issue + Diff + Evidence. |
| Feeding a 100-page PDF as the whole spec | The context fills with noise. | Extract the relevant sections with `agents/context-assembly.md` first. |
| "I think this is fine to merge" | It won't merge. The Evidence Gate must be green and the Aggregator ✅. | Wait for the Coordinator to report Ready. |
| Interrupting mid-run to hurry it | Interrupting = inconsistent state. | Read `PROJECT_STATUS.md` / the task list instead of grabbing the wheel. |
| Treating it as a one-shot coding prompt | It isn't a prompt, it's a harness. | Use it to run a product, not to write one line. |

### When (not) to use it

| Scenario | Use Harness? |
|---|:---:|
| Turning a PRD into an MVP | ✅ Mandatory |
| Several Issues in flight at once | ✅ Mandatory |
| Taking over an old project, paying down debt | ✅ Strongly recommended |
| Auditing a repo that has lost the thread | ✅ Strongly recommended |
| Cross-team / cross-CLI collaboration | ✅ Recommended |
| A one-line typo / copy / config change | ❌ Skip |
| A throwaway script or prototype | ❌ Skip |
| Just talking through an architecture idea | ❌ Skip |

### Maintenance

```bash
# Upgrade to the latest version
npx -y skills update lora-sys/ai-engineering-harness -g

# Check which version is installed
npx skills list -g

# Add a git commit hook that keeps the docs/ index fresh
cat > .githooks/post-commit <<'HOOK'
#!/usr/bin/env bash
bash <(curl -fsSL https://raw.githubusercontent.com/lora-sys/ai-engineering-harness/main/scripts/refresh-index.sh)
HOOK
chmod +x .githooks/post-commit
git config core.hooksPath .githooks
```

After each Phase, the Coordinator automatically runs `workflows/06-phase-summary.md`
and `workflows/08-memory-evolution.md`, promoting what was actually learned into
`memory/<role>-memory.md`. Next Session, new Agents read these before starting work.

### Further reading

- [`SKILL.md`](./SKILL.md) — the entry document every agent loads
- [`QUICKSTART.md`](./QUICKSTART.md) — 9-section tutorial with copy-paste prompt templates
- [`agents/`](./agents/) — 18 agent personas
- [`workflows/`](./workflows/) — 10 closed-loop workflows
- [`templates/`](./templates/) — 16 templates (Issue / Plan / PR / Review / Evidence / Phase / ADR / ...)
- [`checklists/`](./checklists/) — 6 acceptance checklists
- [`references/`](./references/) — 11 deep-dive docs
- [`examples/`](./examples/) — 7 filled samples
- [`docs/case-studies/README.md`](./docs/case-studies/README.md) — before/after takeover cases
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — maintenance scripts and the contribution process

## Showcase — what this actually produces

This section is filled with **real output** from a real end-to-end run (`feature/15-install-status`, commit `4f311e2`, merged via `f5b26d1`). Every artifact below was captured during the actual workflow, not fabricated for the README.

#### Closed loop (v1.2.0)

![Closed loop](assets/closed-loop-v1.2.svg)

Phases highlighted yellow are new in v1.2.0. The CI gate (red) is the strongest gate in the harness — stronger than adversarial review, because a red CI is the only failure that is mechanical and observable.

#### Phase 3.0 — context bundle (real excerpt)

`scripts/context-bundle.sh --out docs/evidence/15/context-bundle.md` produces an 18 KB / 281-line markdown file. Sub-agents spawned in later phases read it instead of each running their own `git log` / `ls` / `find`:

_(Captured at `765ecd0` / `v1.2.0` — this is the frozen output of that run, not current HEAD. Its value is that it is a real capture, so it is not re-dated.)_

```markdown
# Context bundle

_Generated 2026-07-13T10:05:54+08:00 by scripts/context-bundle.sh_
_Repo: git@github.com:lora-sys/ai-engineering-harness.git_
_HEAD: 765ecd0_
## Repo identity

- **origin**: `git@github.com:lora-sys/ai-engineering-harness.git`
- **branch**: `main`
- **HEAD**: `765ecd0`
- **tag**: `v1.2.0`
- **working tree**: clean

## Recent commits (last 20)

765ecd0 feat(scripts): context-bundle.sh + compact-report.sh (v1.2.0)
5a65b7a feat(hooks): SessionStart hook auto-reads .claude/SESSION.md (v1.1.0)
...

## Harness roster

### Workflows
  - `00-project-bootstrap.md` — Workflow — Project Bootstrap
  - `01-feature-delivery.md` — Workflow — Feature Delivery
  ...

### Agents
  - `architecture-reviewer`
  - `backend`
  - `bug-hunter`
  - `coordinator`
  ...
```

Wall time: ~5.6 s parallel / ~8.0 s sequential. Sections run in parallel as backgrounded subshells. Source: [references/context-bundle.md](./references/context-bundle.md).

#### Phase 5 — compact report (real)

`scripts/compact-report.sh --evidence-dir docs/evidence/15 --branch feature/15-install-status --agent backend` produces a 374-byte JSON the parent Coordinator parses instead of re-reading the 20 KB implementation narrative:

```json
{
  "agent": "backend",
  "branch": "feature/15-install-status",
  "commit": "4f311e2",
  "files": 2,
  "test": "pass",
  "blockers": ["needs review"],
  "evidence_paths": [
    "compact-report.json",
    "implementation-report.md",
    "test-results/manual.log"
  ],
  "evidence_size_bytes": 1407,
  "report_md": "implementation-report.md",
  "generated_at": "2026-07-13T10:08:44+08:00"
}
```

Test status auto-detected by grepping `test-results/*` (any FAIL marker wins over PASS). Source: [references/compact-report.md](./references/compact-report.md).

#### Honest self-review of the e2e run

What worked:

1. `context-bundle.sh` gave the implementer everything they needed in one read — no redundant exploration.
2. Worktree discipline (`git worktree add ... -b feature/...`) kept `main` untouched.
3. The harness's own validators (validate-meta.sh + check-templates.sh) caught the 2 script-syntax errors during development.
4. `compact-report.sh` produced a structured 374-byte summary the parent actually needs.

What friction showed up:

1. **Editing complex bash with Python subshells is fragile** — my first rewrite attempt failed silently due to heredoc quoting. Lesson: write Python to a file first, don't inline.
2. **`--status` initially created `settings.json` on a fresh machine** — the file-creation check ran before the action switch. The 7-test self-test caught it. Without the test, that would have shipped as a side effect.
3. **Adversarial review was one-line self-Q&A** — in production I'd spawn `bug-hunter` and `behavior-reviewer`. Solo-maintainer mode is harder to do honestly.
4. **GitHub Issue #15 doesn't exist** — the harness workflow says every change starts as an Issue. Working on your own repo makes that easy to skip.

Full self-review: [docs/evidence/15/self-review.md](./docs/evidence/15/self-review.md).

#### What this is NOT

- Not a screenshot of a polished demo. The artifacts above are from a real `git log` / `ls` / `cat` of the working tree at commit `4f311e2`.
- Not a green-tick theatre. The honest self-review section above names real gaps.
- Not a replacement for adversarial review. The e2e ran with solo self-review; in production you'd run `bug-hunter` + `behavior-reviewer` per the harness's closed loop.

### Case studies

Before/after takeovers: [docs/case-studies/README.md](./docs/case-studies/README.md)

Every number in an **evidenced** case traces to a commit. **Illustrative** cases
show what a takeover should look like; their numbers are design targets. The line
between the two is in the table, not left to the reader:

| Case | Before → After | Type · Evidence |
|------|----------------|-----------------|
| Internal tool project (0 → 47 tests) | Chaos 35 → 87 | Illustrative · no public repo to check |
| install-session-hook (harness self-audit) | 0 → full evidence pack | **Evidenced** · [`docs/evidence/15/`](./docs/evidence/15/) |
| Dashboard one-click takeover | 23 findings in 30s | Illustrative · output shape real, findings constructed |
| Passing tests ≠ effective tests (#9) | 9 detectors, 24 decorative tests → 10 detectors, 39 real assertions | **Evidenced** · commits `9cbff11`, `1c9900f` |
| The green CI lied to us (#13) | CI green while local was 85/108 + infinite hang → 108/108 in 75s | **Evidenced** · commit `f92fd53` |

## Roadmap

Three lanes: **Active** (in progress this week), **Backlog** (planned, queued), **Done** (shipped).

#### Active

_Nothing in progress. The most recent round (issues #9 / #10 / #11) is fully
merged — see the "unreleased" entry under Done._

#### Backlog

- **Harness: measure the false-positive rate of the other 8 vibe-signs detectors.**
  Only `security` and `code-hygiene` have been measured against third-party code
  (282 MB / 70,731 files: 410 → 81 and 153,554 → 1,114). At that hit rate the
  remaining 8 likely carry comparable noise — and noise teaches users to ignore
  the whole scan, which is worse than one missing detector.
- **Harness: secret detection misses hyphenated keys.** `sk-live-xxx` (Stripe
  style) does not fire when the variable name lacks `key`/`token`/`secret`.
  Re-measure the false-positive rate before loosening the pattern.
- **Harness: the detector count is kept in sync by hand.** It is written in three
  places (`parser.js` numbered comments, `SKILL.md`,
  `chaos-score-algorithm.md`) and drifted once this round. Worth adding to the
  `check-templates.sh` gate the way directory counts already are.

#### Done

- **Unreleased (on `main`, after `0.2.2`)** — issues #9 / #10 / #11 all closed:
  - secret detection no longer exempts config files (#17) — a repo with an AWS
    key in `src/config.ts` used to score A, because the detector skipped the one
    path where real keys are most often pasted
  - comment detection no longer reports JSDoc as residue (#19) — 99.1% of its
    output on the corpus was documentation; it also never caught plain
    `// const x = 1`, which it now does
  - README structure rebuilt (#14) — repaired a fence corruption that inverted
    rendering for 248 lines, and added markdown-structure + count-drift gates to
    `check-templates.sh`
  - case studies labelled by type, plus 2 evidenced cases where every number
    traces to a commit (#16)
  - 132 bats tests across 19 files
- **v1.7.0** — GHA workflow (`test.yml` runs harness tests on every PR) + `scripts/release.sh` (one-command release flow) + 4 frontend-creative theme variants + Awwwards / anti-drift gates wired into workflows; 69 bats tests
- **v1.6.0** — `skills/frontend-creative/` sibling skill (Awwwards-grade creative web UIs) + 2 `install.sh` bug fixes; 66 bats tests
- **v1.5.0** — PR intake flow (`workflows/09-pr-intake.md`) + Local-first principle (SKILL.md #9) + decision matrix; closes Roadmap Part 1
- **v1.4.0** — `scripts/sync-project.sh` + 58 bats tests (sync already-bootstrapped projects)
- **v1.3.0** — bats test suite (38→58 tests) + 3 install-session-hook regressions fixed
- **v1.2.1** — `install-session-hook.sh --status` + README Showcase with real e2e artifacts
- **v1.2.0** — `context-bundle.sh` + `compact-report.sh` (parallel dump + structured JSON summary)
- **v1.1.0** — SessionStart hook for `.claude/SESSION.md` (read-only)
- **v1.0.x** — CI as a blocking gate, validators, check-templates, install-session-hook, D-013 release-process fix

## Troubleshooting · 安装常见问题

### "I see only SKILL.md, not workflows/ or templates/"

This is a known quirk of the Vercel `npx skills` CLI: it ships a *thin* canonical install
(`~/.agents/skills/<name>/SKILL.md` only) and lets per-agent installs decide between
copy or symlink. Symlinked agents like **Claude Code** then see nothing but `SKILL.md`
because they read through the thin canonical.

**Workarounds** (in order of preference):

1. **Fat install — git clone + symlink everything**:

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/lora-sys/ai-engineering-harness/main/install.sh) --fat-install
   ```

   Or, if you have the repo cloned:

   ```bash
   ./install.sh --fat-install
   ```

   This `git clone`s the repo to `/tmp/ai-engineering-harness-fat` and replaces every
   per-agent install with a symlink to the full bundle. After this, every agent that
   allows a writable parent dir will see `workflows/`, `templates/`, `agents/`, etc.
   Use `--clonedir <path>` to pick a different clone target.

2. **Read the docs from the GitHub repo**: <https://github.com/lora-sys/ai-engineering-harness/tree/main>

3. **Use git-copilot style — clone and symlink one agent**:

   ```bash
   git clone --depth 1 https://github.com/lora-sys/ai-engineering-harness.git /tmp/aeh
   ln -s /tmp/aeh ~/.claude/skills/ai-engineering-harness
   ```

### Why didn't my `npx skills add` install the bundle?

We did everything right on our end (the repo has `meta.json`, 10 topics, MIT license,
proper `SKILL.md` frontmatter), but the canonical install under
`~/.agents/skills/ai-engineering-harness/` ends up containing only `SKILL.md`. That's
the Vercel CLI's design. We're tracking a fix at
<https://github.com/vercel-labs/skills/issues/1630>.

## Maintainer docs

Maintenance scripts (`validate-meta.sh`, `changelog-auto.sh`, `new-session.sh`,
`new-evidence.sh`, `new-worktree.sh`, `refresh-index.sh`), the contribution process,
and the discoverability notes all live in **[CONTRIBUTING.md](./CONTRIBUTING.md)**.

The skill family — `$ai-engineering-harness`, `$build-agent-app`,
`$frontend-creative`, plus the optional `$dashboard` panel — is described in
[What's inside](#whats-inside) above. To install a sibling on its own:

```bash
bash install.sh --skill build-agent-app          # only the sibling
bash install.sh --fat-install --skill all        # git clone + symlink everything
```

| Want to … | Trigger |
| --- | --- |
| Build a software product (engineering org) | `$ai-engineering-harness` |
| Design / take over / refactor an **agent app** | `$build-agent-app` |
| Generate an Awwwards-grade web UI | `$frontend-creative` |
| Scan a repo for vibe residue and watch a kanban | `$dashboard` |

## License

MIT — see [LICENSE](./LICENSE).

---
