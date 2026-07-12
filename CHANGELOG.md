# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note on versioning for this skill**: The skill's `description` and the
> install instructions *are* the API surface — they're what the agent reads
> to decide whether to invoke. Doc-only changes that clarify routing,
> safety, or onboarding therefore bump the patch number. See `memory/notes-2026-07-11.md`
> for the rationale (decision D-006).

## [1.0.2] - 2026-07-12

CI/CD promoted from "a step" to "a blocking gate" in the closed loop.

### Added
- **`SKILL.md` §1 Principle #8** — *"CI/CD is a blocking gate, not a checkpoint."* The strongest gate in the harness, stronger than adversarial review.
- **`references/cd-monitoring.md`** — pattern doc for CI watching: polling cadence, failure classification, "at most one re-run before real-defect triage" rule, Owner hand-back.
- **`memory/notes-2026-07-12.md`** — D-011 ("CI/CD is a blocking gate, not a step") with Status · Context · Decision · Why · Consequence · Revisit-when.

### Changed
- **`workflows/01-feature-delivery.md` Phase 7** — renamed `(BLOCKING GATE — do not advance while red)`. Owner watches CI from the first commit. Coordinator blocks review / merge / Done / Close until green. Rescue loop is `04-ci-recovery.md`. Same-class second failure ⇒ `ci`-tagged Issue + `memory/lessons.md` line.
- **`agents/coordinator.md`** — *"Red CI = blocked phase. Do NOT advance to adversarial review, do NOT close the Issue, do NOT merge while CI is red."*
- **`agents/qa.md`** — CI/CD-watching role added: poll every ~60–120 s, restart on every push, capture failing log + class on first red, file `ci` Issue + lessons entry on second red of same class.
- **`SKILL.md`** — loop diagram marks CI as `**(BLOCK: do not advance while red)**`. Cross-cutting Evidence table makes "CI green (mandatory)" the first row of Infra/DevOps. References list points to `cd-monitoring.md`. §13 anti-patterns list carries the new "Done while CI is red" rule twice so it survives rewording.
- **`checklists/evidence-gate.md`** — *"CI is GREEN on the latest commit at the head of the PR branch"* + *"No 'partial CI as green'. All configured checks must pass — lint, tests, build, security scan."* + a required `docs/evidence/<id>/ci-log.txt`.
- **`templates/pr-description.md`** — new `## CI` section (right before `## Risk`) so the PR body has to enumerate the actual checks and the actual run-ids.
- **`CONTRIBUTING.md`** — new §1.5 *"Treat CI status as part of 'the actual path'"* extending D-008 (test the actual path) to remote-system claims. A claim of "CI green" without a run-id is not a claim.
- **`README.md`** — operating principles table now has 8 rows (adds Principle #8 in both Chinese and English).

### Why v1.0.2 (not v1.1.0)
The user-facing `description` of the skill (the routing surface) is unchanged. The harness is still triggered on the same queries; what changed is **how loud** CI is inside the loop when an agent runs the harness. Per D-006, routing-affecting changes bump minor; structural changes bump major; everything else is patch. This is patch.

### Files added / changed

```
+ references/cd-monitoring.md           NEW pattern doc
+ memory/notes-2026-07-12.md            D-011 entry
M  SKILL.md                             Principle #8 + closed-loop BLOCK + references list
M  workflows/01-feature-delivery.md     Phase 7 strengthened
M  agents/coordinator.md                CI-blocking rule
M  agents/qa.md                         CI-watching role
M  checklists/evidence-gate.md          "CI green (mandatory)" + ci-log.txt
M  templates/pr-description.md          New "## CI" section
M  CONTRIBUTING.md                      §1.5 "CI status as part of the actual path"
M  README.md                            Operating principles table bumped to 8 rows
M  CHANGELOG.md                         This entry
```

## [1.0.0] - 2026-07-12

The skill family release. This repo now ships more than one skill.

### Added
- **`skills/build-agent-app/`** — companion skill "Build Agent App". The Agent App Architect: design / take over / refactor an agent app. Writes Agent Contract + Harness Contract, picks an entry workflow (new | takeover | refactor), then hands implementation back to `$ai-engineering-harness`. Triggers on `$build-agent-app`.
- **`scripts/validate-meta.sh`** — extended to walk the entire skill family. With no file argument, it validates `./meta.json` and every `skills/*/meta.json` it finds. `OK: ./meta.json passes schema validation` becomes `Summary: 2 passed, 0 failed`.
- **`meta.json`** at repo root: still the primary entry pointing to `ai-engineering-harness`. Now tags include `skill-family:ai-engineering-harness` and `sibling-skill:build-agent-app` so indexers that don't recurse can still discover the family.
- **`skills/build-agent-app/meta.json`** — the sibling's own metadata. Passes our own `validate-meta.sh --strict` and the upstream skill-creator `quick_validate.py`.
- **`install.sh`** — refactored from single-skill to multi-skill via the `SKILL_SOURCES` map. New flag `--skill <name>` chooses `ai-engineering-harness`, `build-agent-app`, or `all` (default). Maintains full back-compat with the old `--all` / `--target X` / `--uninstall` / `--fat-install` behaviour.
- **`README.md`** — new "Companion skills" section. Documents the family, when to trigger which skill, and a `when-to-call-which-skill` table.

### Changed
- **Skill status: single skill → skill family.** `npx skills add lora-sys/ai-engineering-harness` still installs only the primary skill at canonical (unchanged). The sibling rides along only when using our `bash install.sh` (with `--skill all`, the default).
- **Validation contract.** Both meta.json files now pass `scripts/validate-meta.sh --strict` with 0 warnings. Run as part of release pre-flight.

### Why v1.0.0 (not v0.2.0)
The repository evolved from "one skill prototype" to "a vetted skill family with hand-off contracts". That's a major version-bump-worthy transition. The skill description / install behaviour of `ai-engineering-harness` itself is unchanged, so existing `npx skills add` users see no disruption.

### Install / Update

```bash
# Existing: still works, no behavior change
npx -y skills update lora-sys/ai-engineering-harness -g

# New: install the family (both skills at 38 CLI agent dirs)
bash install.sh --all                        # both
bash install.sh --skill build-agent-app      # only sibling
bash install.sh --fat-install               # git clone + symlink, both skills
```

### Files added / changed

```
+ skills/build-agent-app/                NEW skill folder (SKILL.md + references/ +
                                          templates/ + workflows/ + scripts/ +
                                          examples/ + agents/openai.yaml + meta.json)
M  install.sh                            multi-skill aware, --skill flag, family walk
M  scripts/validate-meta.sh              walks skills/*/meta.json when no FILE given
M  README.md                             +49 lines (Companion skills section)
M  meta.json                             +2 tags (skill-family:..., sibling-skill:...)
M  CHANGELOG.md                          v1.0.0 entry (this file)
```

### Compatibility

- No behavior change for `npx skills add lora-sys/ai-engineering-harness -g --all` users.
- The new sibling is opt-in via `bash install.sh --skill build-agent-app`.
- All previous per-CLI-agent routing descriptions remain valid.


## [0.1.4] - 2026-07-11

### Added
- **`meta.json`** at the repo root — structured metadata for skill indexes (skills.sh and friends). Fields: `id`, `name`, `description`, `category`, `priority`, `tags`, plus an `install` map covering the four install shapes (global / specific-skill / specific-agent / both). Schema compatible with the existing skills.sh convention used in `git-copilot/skills/`.
- **Explicit `--all` safety contract** added to the README in both Chinese and English, placed right after the one-line install section. Documents today's safety (1 skill in repo) and the future risk (sister skills install automatically), and gives four safer alternatives:
  - `npx -y skills add lora-sys/ai-engineering-harness --list` (preview)
  - `-s <skill-name>` (limit to one skill)
  - `-a <agents...>` (limit to specific agents)
  - both flags together (one skill × one agent)
- README now links to `meta.json` so anyone curious about the install contract has one place to look.

## [0.1.3] - 2026-07-11

### Added
- **`memory/notes-2026-07-11.md`** — a project memory file capturing 6 key decisions from this build cycle, each with Context / Decision / Why / Consequence / **Revisit when**:
  - **D-001** Single-skill repo vs multi-skill (chose single)
  - **D-002** `npx skills` unified `~/.agents/skills/` model (preferred over custom `install.sh`)
  - **D-003** `npx skills add --all` is safe in a single-skill repo (today); revisit when adding a sibling
  - **D-004** SVG for diagrams, PNG only at OG / social-card gateways
  - **D-005** skills.sh is auto-crawled from GitHub — optimize repo metadata, no manual submission
  - **D-006** Doc-only changes bump patch version because the skill description is the API surface
- **`assets/social-preview.png`** — 1200×630 PNG, the canonical social-card image (Twitter, GitHub, Slack, Discord unfurls). Distinct from `architecture.svg` — closed-loop ring on the right instead of the full 18-persona org chart.
- README now references the social preview underneath the architecture diagram.

## [0.1.2] - 2026-07-11

### Added
- **`assets/architecture.svg`** — a single 1440×820 SVG diagram showing the full closed loop:
  - Six numbered stages across the top: Issue → Plan → Implement → CI → Adversarial Review → Evidence Gate
  - Coordinator tying every stage together (no business code)
  - 18-persona agent org chart (2 rows × 8 boxes) color-coded by role (implement / review / queue / support)
  - Memory band at the bottom (project, architecture, role memories, lessons, ADRs, phase summaries)
  - Closed-loop curve returning to Issue ①
- **`## Discoverability` section in the README** explaining how `skills.sh` indexes the skill, with `npx skills find` commands users can run locally to verify inclusion.
- Diagram embedded at the very top of the README (right below the badges) so any visitor sees the architecture first.

## [0.1.1] - 2026-07-11

### Added
- **`## 使用指南 · Usage Guide`** section between the existing English content and the compatibility table. Bilingual (Chinese + English) and covers:
  - **4 highest-frequency invocations**: bootstrap from PRD / resume interrupted work / drive one Issue / audit or rescue
  - **7 operating principles** (evidence over vibes, cold-start review, L0–L3 context, Issue as unit, Worktree isolation, Human Approval Gate, memory as state)
  - **7 canonical prompt snippets** ready to copy
  - **Advanced usage** (30-second bootstrap, takeover of legacy repos, cross-CLI handoff, parallel Owners, CI self-recovery)
  - **Anti-patterns table** (7 ways to misuse the harness)
  - **When-(not)-to-use decision matrix**
  - **Maintenance commands** (`skills update`, post-commit hook for index refresh)
  - **Further reading** pointers to the rest of the repo
- README grew from 389 → 585 lines.

## [0.1.0] - 2026-07-11

### Added
- Initial release
- 18 agent personas (Coordinator, Explore, Plan, Frontend, Backend, Database, QA, Bug Hunter, Behavior Reviewer, Architecture Reviewer, Security Reviewer, UI Reviewer, Conflict Resolver, Release, Review Aggregator, Context Assembly, Memory Curator, Scope reference)
- 9 closed-loop workflows (project bootstrap, feature delivery, issue lifecycle, adversarial PR review, CI recovery, conflict resolution, phase summary, release prep, memory evolution)
- 16 templates (Issue types for bug/feature/refactor/spike, Implementation Plan, PR description, Review Report, Evidence Pack index, Phase Summary, Context Manifest, ADR, Project Status, CLAUDE/AGENTS, memory file, session files)
- 6 acceptance checklists (Evidence Gate, PR Merge, Frontend, Backend, Database, Security)
- 6 reference docs (context levels L0-L3, document indexing, worktree discipline, agent spawning, evidence formats, shell tooling)
- 6 filled examples (Issue, Implementation Plan, PR, Review Report, Evidence Pack, Phase Summary)
- 5 helper scripts (new-session, new-evidence, new-worktree, refresh-index, changelog)
- `install.sh` installer targeting 38 CLI coding agents (Claude Code, Codex, Cursor, Gemini, Qwen, Grok, OpenCode, Hermes, Aider Desk, Continue, Roo, etc.)
- Bilingual README (English + Chinese)
- MIT license

## Install

```bash
npx -y skills add lora-sys/ai-engineering-harness -g --all
```

## Releases

- [0.1.4]: https://github.com/lora-sys/ai-engineering-harness/releases/tag/v0.1.4
- [0.1.3]: https://github.com/lora-sys/ai-engineering-harness/releases/tag/v0.1.3
- [0.1.2]: https://github.com/lora-sys/ai-engineering-harness/releases/tag/v0.1.2
- [0.1.1]: https://github.com/lora-sys/ai-engineering-harness/releases/tag/v0.1.1
- [0.1.0]: https://github.com/lora-sys/ai-engineering-harness/releases/tag/v0.1.0
