# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> **Note on versioning for this skill**: The skill's `description` and the
> install instructions *are* the API surface — they're what the agent reads
> to decide whether to invoke. Doc-only changes that clarify routing,
> safety, or onboarding therefore bump the patch number. See `memory/notes-2026-07-11.md`
> for the rationale (decision D-006).

## [1.7.0] - 2026-07-13

Closes the 4 Roadmap Backlog items. Operational tooling (GHA + release script) + frontend-creative content (4 theme variants + wired Awwwards / anti-drift gates).

### Added

- **`.github/workflows/test.yml`** — runs `validate-meta.sh --strict` + `check-templates.sh --strict` + `scripts/run-tests.sh` on every PR and push to main. Catches harness regressions before merge (this is the harness using its own evidence-gate on itself).
- **`scripts/release.sh <version>`** — automates the full release flow. Verifies `meta.json` version matches the requested version, runs validators, commits pending changes, pushes tag + branch, creates the GitHub release with notes auto-extracted from `CHANGELOG.md` for that version, updates local fat + thin installs.
- **`scripts/frontend-creative/references/theme-{a,b,c,d}-*.md`** — 4 fully-fleshed theme variants (Cyberpunk / Minimal Gallery / Retro Acid / Future 3D). Each file: Tailwind config (colors / fonts / sizes / shadows / animations), motion presets (GSAP + Framer Motion + R3F snippets), reference brand list, anti-patterns.
- **`scripts/frontend-creative/references/theme-variants.md`** — now an index pointing to the 4 per-theme files.
- **`tests/release.bats`** (NEW, 3 tests) — covers missing-version-arg, meta.json version mismatch, CHANGELOG regex.

### Changed

- **`skills/frontend-creative/workflows/02-local-refinement.md`** — Anti-drift check is now **mandatory** (was: suggested). Hard rule added: if "more generic" or any single rejection criterion fires twice in a row, stop and restart.
- **`skills/frontend-creative/workflows/03-visual-regression-check.md`** — Awwwards review checklist (from `templates/review-checklist.md`) is now the first step. Subsequent steps renumbered.
- **`skills/frontend-creative/workflows/04-ship.md`** — review-checklist run is now a pre-ship **gate**, not a suggestion.
- **`skills/frontend-creative/templates/iteration-log.md`** — anti-drift check expanded to 5 YES/NO questions + explicit reject criteria + hard rule about two consecutive failures.
- **`skills/frontend-creative/templates/review-checklist.md`** — explicit numeric thresholds (< 36 reject / 36-47 needs work / ≥ 48 ship-able) + reject-criteria list.

### Why v1.7.0 (not v1.6.1)

Two new files in `.github/workflows/` + `scripts/release.sh` is genuine new infrastructure. Plus 4 substantive theme docs (~400 lines) + workflow enforcement changes. Per D-006, tooling + content = minor.

### Files changed

```
+ .github/workflows/test.yml                       NEW (28 lines)
+ scripts/release.sh                                NEW (~80 lines)
+ tests/release.bats                                NEW (3 tests)
+ skills/frontend-creative/references/theme-a-cyberpunk.md       NEW
+ skills/frontend-creative/references/theme-b-minimal-gallery.md  NEW
+ skills/frontend-creative/references/theme-c-retro-acid.md      NEW
+ skills/frontend-creative/references/theme-d-future-3d.md       NEW
M  skills/frontend-creative/references/theme-variants.md  now an index
M  skills/frontend-creative/workflows/02-local-refinement.md  mandatory anti-drift
M  skills/frontend-creative/workflows/03-visual-regression-check.md  mandatory Awwwards
M  skills/frontend-creative/workflows/04-ship.md  review-checklist as pre-ship gate
M  skills/frontend-creative/templates/iteration-log.md  expanded anti-drift gate
M  skills/frontend-creative/templates/review-checklist.md  explicit thresholds
M  meta.json                                version: 1.6.0 → 1.7.0
M  skills/build-agent-app/meta.json         version: 1.6.0 → 1.7.0
M  skills/frontend-creative/meta.json       version: 1.6.0 → 1.7.0
M  CHANGELOG.md                            This entry
```

### Upgrade

```bash
npx -y skills update lora-sys/ai-engineering-harness -g
# Optional: use the new release script (CI runs on PRs automatically)
./scripts/release.sh 1.7.0   # if you have a v1.7.0 ready
```

## [1.6.0] - 2026-07-13

New sibling skill **`$frontend-creative`** for Awwwards-grade creative web UIs. Closes the 3 Part-2 issues on the Roadmap.

### Added

- **`skills/frontend-creative/`** (NEW sibling skill, mirrors `build-agent-app` pattern):
  - `SKILL.md` — entry, when to use, operating principles, hand-off to `$ai-engineering-harness`.
  - `meta.json` — for indexers (`sibling-skill:frontend-creative` tag).
  - `references/creative-ui-design-spec.md` — the 17-section Creative UI Design Spec (full text).
  - `references/theme-variants.md` — Cyberpunk / Minimal Gallery / Retro Acid / Future 3D + Tailwind tokens + motion presets.
  - `references/prompt-library.md` — reusable prompts per phase.
  - `templates/design-brief.md`, `templates/iteration-log.md`, `templates/review-checklist.md`.
  - `workflows/00..04-*.md` — design-brief → macro-design → local-refinement → visual-regression → ship.
  - `agents/creative-frontend.md` — the design-aware agent persona.
- **`install.sh`** — `--skill frontend-creative` now supported alongside `--skill ai-engineering-harness` and `--skill build-agent-app`. `--skill all` (the default) installs the full family.
- **`SKILL.md`** — Adjacent skills note in §2 lists all 3 family members and when to route to each.
- **`meta.json`** (root) — added `sibling-skill:frontend-creative` tag so family walks pick it up.
- **`tests/install.bats`** (NEW, 8 tests) — covers help, --skill frontend-creative + --target codex installs correctly, doesn't install main harness, build-agent-app regression, --uninstall, --skill all (the family), unknown-arg rejection, combined-flag-parsing regression.

### Fixed

- **`install.sh`** arg parser — pre-existing bug: combined `--skill X --target Y` was being misparsed (outer `shift` consumed `--target`). Each arm now shifts its own args; no outer shift. Caught by the new install tests.
- **`install.sh`** `--skill all --target <name>` — pre-existing bug: only installed the FIRST skill alphabetically (`build-agent-app`) instead of all three. Inner `break` was leaking out of the per-target loop. Fixed; now installs the whole family.

### Why v1.6.0 (not v1.5.1)

A new sibling skill is net-new capability that significantly expands the family. Per D-006, structural changes warrant a minor bump. Plus two install.sh fixes that were caught by the new test suite.

### Files changed

```
+ skills/frontend-creative/                       NEW (8 files: SKILL.md + meta.json + references/ + templates/ + workflows/ + agents/)
+ tests/install.bats                              NEW (8 tests)
M  install.sh                                     +frontend-creative in SKILL_SOURCES; 2 arg-parser fixes
M  SKILL.md                                       +Adjacent skills note (3 family members)
M  meta.json                                      version: 1.5.0 → 1.6.0 + sibling-skill tag
M  skills/build-agent-app/meta.json               version: 1.5.0 → 1.6.0
M  skills/frontend-creative/meta.json             NEW (v1.6.0)
M  tests/sync-project.bats                        idempotency test uses bounded fence-block capture
M  tests/validate-meta.bats                       family-walk test uses grep -qE + dynamic count regex
M  CHANGELOG.md                                   This entry
```

Closes GitHub issues #5, #6, #7.

## [1.5.0] - 2026-07-13

Refined contribution/PR intake flow with the **Local-first principle**. Closes the 4 Part-1 issues on the Roadmap.

### Added

- **`workflows/09-pr-intake.md`** (NEW) — PR intake workflow. Steps: triage against project history → check for local equivalence → sequence PRs oldest-first → self-review against project context → merge/comment/close decision.
- **`agents/conflict-resolver.md`** — new section **"Local-first for overlapping changes (Principle #9)"** with detection grep + comment template.
- **`references/pr-intake-decision-matrix.md`** (NEW) — 12-row merge/comment/close rubric.
- **`SKILL.md`** — Principle #9: *"Local-first for overlapping changes."* Anti-pattern added: *"Merging a PR that duplicates local code."*
- **`README.md`** — operating principles table bumped to 9 rows (bilingual). Workflows list updated. Roadmap section.

### Why v1.5.0 (not v1.4.1)

Adds an Operating Principle. Per D-006, principle additions are patch-level. But the workflow + agent + reference doc together represent a coherent new capability (PR intake as a first-class workflow), which warrants a minor bump.

### Files changed

```
+ workflows/09-pr-intake.md                       NEW (90 lines)
+ references/pr-intake-decision-matrix.md         NEW (37 lines)
M  agents/conflict-resolver.md                    +Local-first section (43 lines)
M  SKILL.md                                       Principle #9 + anti-pattern
M  README.md                                      operating principles table → 9 rows
M  meta.json                                      version: 1.4.0 → 1.5.0
M  skills/build-agent-app/meta.json               version: 1.4.0 → 1.5.0
M  CHANGELOG.md                                   This entry
```

Closes GitHub issues: #1 (workflow), #2 (agent), #3 (decision matrix), #4 (principle).

## [1.4.0] - 2026-07-13

`scripts/sync-project.sh` — sync already-bootstrapped projects to the current harness version. Plus 18 new bats tests (56 total).

### The user problem this solves

When a project is bootstrapped at harness v1.0.0 and the harness ships v1.4.0 with new capabilities, the project keeps its old state. The install location updates via `npx skills update`, but the project's `.harness-state.json` (didn't exist), AGENTS.md (no fenced block for v1.2 capabilities), and evidence dirs (no `compact-report.json`) all stay at v1.0.0. The user has to manually diff CHANGELOG and apply each change.

`sync-project.sh` automates this.

### Added

- **`scripts/sync-project.sh`** — idempotent project sync. Detects current state via `.harness-state.json` (or treats as "pre-v1.0" if missing). Default mode = plan (dry-run). `--apply` runs the migrations:
  - Write/update `.harness-state.json` (with `.bak` backup if pre-existing).
  - Ensure `.github/ISSUE_TEMPLATE/` + `.github/PULL_REQUEST_TEMPLATE.md` exist (copies from harness templates).
  - Patch fenced block `<!-- HARNESS:START harness-capabilities -->` in AGENTS.md (user content outside is preserved).
  - Back-fill `compact-report.json` for each existing `docs/evidence/<id>/` (only when missing — never overwrites).
- **`tests/sync-project.bats`** (NEW, 12 tests) — covers help, refusal modes, dry-run, --apply, idempotency, AGENTS.md preservation, compact-report non-overwrite, status drift reporting.
- **`tests/changelog-auto.bats`** (NEW, 2 tests) — covers --help + refuses to clobber existing CHANGELOG.
- **`tests/new-session.bats`** (NEW, 2 tests) — covers no-args + valid-id paths.
- **`tests/new-evidence.bats`** (NEW, 2 tests) — covers no-args + valid-id paths.

### Changed

- **`scripts/new-session.sh` + `scripts/new-evidence.sh`** — added `Usage:` line in header comment block (so `--help`-style output convention is consistent across the harness).

### Why v1.4.0 (not v1.3.1)

`sync-project.sh` is net-new capability and addresses the second-most-asked question after "what does it do?" — "how do I upgrade?". Per D-006, new capability → minor.

### Files changed

```
+ scripts/sync-project.sh                     NEW (project-state sync)
+ tests/sync-project.bats                     NEW (12 tests)
+ tests/changelog-auto.bats                   NEW (2 tests)
+ tests/new-session.bats                      NEW (2 tests)
+ tests/new-evidence.bats                     NEW (2 tests)
M  scripts/new-session.sh                     Usage prefix in header
M  scripts/new-evidence.sh                    Usage prefix in header
M  CONTRIBUTING.md                            (no changes — already covers run-tests.sh)
M  meta.json                                  version: 1.3.0 → 1.4.0
M  skills/build-agent-app/meta.json           version: 1.3.0 → 1.4.0
M  memory/notes-2026-07-12.md                 D-016 added
M  CHANGELOG.md                               This entry
```

### Upgrade

```bash
npx -y skills update lora-sys/ai-engineering-harness -g
# Then in each existing harness-managed project:
bash /path/to/ai-engineering-harness/scripts/sync-project.sh            # dry-run preview
bash /path/to/ai-engineering-harness/scripts/sync-project.sh --apply    # actually sync
```

## [1.3.0] - 2026-07-13

Add bats test framework for the harness's own shell scripts. 38 tests across 6 files. Caught 3 real regressions in `install-session-hook.sh` while writing the test suite.

### Added

- **`tests/`** (NEW directory, 6 `.bats` files, 38 tests):
  - `install-session-hook.bats` (10 tests) — install / idempotency / --status / --uninstall / --dry-run / bad-target / preservation of other hooks / regression for the `--status does NOT create settings.json` bug.
  - `context-bundle.bats` (5 tests) — bundle structure, parallel ≡ sequential, --commits depth control, --help, --commits validation.
  - `compact-report.bats` (12 tests) — required inputs, JSON shape, test status auto-detection (PASS/FAIL/mixed PASS+FAIL → FAIL wins), --blocker accumulation, --files-changed override, written file existence.
  - `check-templates.bats` (6 tests) — happy path, missing-heading detection, inline-reference false-positive guard.
  - `validate-meta.bats` (5 tests) — happy path, version-required, semver format, family walk.
  - `changelog.bats` (2 tests) — overwrite guard, --force override.
- **`scripts/run-tests.sh`** (NEW) — bats runner. Locates bats via `command -v` or `~/.local/bin/bats`. Filters by name (`scripts/run-tests.sh install` runs only install-session-hook.bats). Exits 1 if bats not installed (with install instructions for three platforms).

### Fixed (caught while writing the test suite)

- **`scripts/install-session-hook.sh`**: `--status` now propagates a non-zero exit code when the hook is not installed. Previously exited 0 unconditionally, so callers couldn't script on it.
- **`scripts/install-session-hook.sh`**: invalid `--target` value (e.g., `--target galaxy`) is now caught up front instead of twice in a subshell where `exit 1` only killed the subshell. Cleaner failure mode, exits 1 with one error message.
- **`scripts/install-session-hook.sh`**: `--help` now prints a `Usage:` line (cosmetic but matches what the bats test asserts).
- **`scripts/context-bundle.sh`**: `--commits` now validates that the value is a positive integer. Previously `--commits abc` silently fell through to `git log -n abc` and produced unexpected output.
- **`scripts/compact-report.sh` + `scripts/context-bundle.sh`**: help blocks now lead with `Usage:` to match what users (and the bats `--help` tests) expect.

### Changed

- **`CONTRIBUTING.md`** — pre-commit step 4 now requires `scripts/run-tests.sh` (38 bats tests) alongside `validate-meta.sh --strict` and `check-templates.sh --strict`.
- **`SKILL.md`** — scripts list updated to mention the new scripts and the test runner.
- **`README.md`** — repository layout block updated to include `tests/` and `hooks/`.
- **`memory/notes-2026-07-12.md`** D-015 — durable decision: bats for harness shell scripts.

### Why v1.3.0 (not v1.2.2)

This is net-new capability (testing infrastructure). Per D-006, install-behavior changes are patch, but **new tooling + fixed real bugs discovered by it** warrants a minor bump.

### Files changed

```
+ tests/install-session-hook.bats               NEW (10 tests)
+ tests/context-bundle.bats                     NEW (5 tests)
+ tests/compact-report.bats                     NEW (12 tests)
+ tests/check-templates.bats                    NEW (6 tests)
+ tests/validate-meta.bats                      NEW (5 tests)
+ tests/changelog.bats                          NEW (2 tests)
+ scripts/run-tests.sh                          NEW (bats runner)
M  scripts/install-session-hook.sh              --status exit, target validation, Usage prefix
M  scripts/context-bundle.sh                    --commits validation, Usage prefix
M  scripts/compact-report.sh                    Usage prefix
M  CONTRIBUTING.md                              pre-commit step 4 adds run-tests.sh
M  SKILL.md                                     scripts list updated
M  README.md                                    repository layout updated
M  meta.json                                    version: 1.2.1 → 1.3.0
M  skills/build-agent-app/meta.json             version: 1.2.1 → 1.3.0
M  memory/notes-2026-07-12.md                   D-015 added
M  CHANGELOG.md                                 This entry
```

### Upgrade

```bash
npx -y skills update lora-sys/ai-engineering-harness -g
# Then install bats if you want to run the test suite locally:
npm install -g bats && ln -sf $(npm root -g)/bats/bin/bats ~/.local/bin/bats
bash scripts/run-tests.sh   # should report "ok 1..38"
```

## [1.2.1] - 2026-07-13

End-to-end polish: real feature delivery (adds `install-session-hook.sh --status`), Showcase section in README with the actual artifacts captured during that run, and a small closed-loop diagram.

### Added

- **`scripts/install-session-hook.sh --status`** (NEW flag) — reports whether the SessionStart hook is currently installed per target without modifying any files. Exits 0 if installed, 1 if not. Critically: does **NOT** create `settings.json` when the file is missing (status is read-only by design). Caught by self-test in the e2e run; the first iteration created the file, the self-test caught it, fix shipped.
- **`assets/closed-loop-v1.2.svg` + `.png`** (NEW) — small closed-loop diagram showing the 6 main phases, the Evidence gate at the center, the v1.2.0 additions highlighted, and the v1.0.2 CI gate as the blocking gate. 5.3 KB SVG, 60 KB PNG.
- **`README.md` Showcase section** — real artifacts (excerpts from a real `context-bundle.md`, the actual `compact-report.json`, and an honest self-review of friction encountered during the e2e run). Both English and Chinese versions.

### Captured during e2e

- `docs/evidence/15/context-bundle.md` — 281-line bundle from Phase 3.0.
- `docs/evidence/15/implementation-report.md` — free-form report.
- `docs/evidence/15/test-results/manual.log` — 7-test self-test log.
- `docs/evidence/15/compact-report.json` — Phase 5 structured summary.
- `docs/evidence/15/self-review.md` — honest friction notes (heredoc quoting, --status side effect, solo adversarial review, missing GitHub Issue).

### Why v1.2.1 (not v1.3.0)

The new feature (`--status`) is a small additive flag. The README polish and SVG are documentation, not new functionality. Per D-006 (additive behavior → patch), this is a patch bump.

### Files changed

```
+ assets/closed-loop-v1.2.svg                 NEW (5.3 KB)
+ assets/closed-loop-v1.2.png                 NEW (60 KB, generated from SVG)
+ docs/evidence/15/                           NEW (e2e artifacts)
M  scripts/install-session-hook.sh            +--status flag (+54/-2)
M  README.md                                  +Showcase section (en + zh)
M  meta.json                                  version: 1.2.0 → 1.2.1
M  skills/build-agent-app/meta.json           version: 1.2.0 → 1.2.1
M  CHANGELOG.md                               This entry
```

### Upgrade

```bash
npx -y skills update lora-sys/ai-engineering-harness -g
```

## [1.2.0] - 2026-07-13

Two new scripts that cut Coordinator work: a one-shot parallel context dump, and a structured compact-report for sub-agent hand-back.

### Added

- **`scripts/context-bundle.sh`** (NEW) — parallelized one-shot dump of repo state into `context-bundle.md`. Eight sections (repo identity, recent commits, working-tree, top-level layout, open issues/PRs, key harness files, memory notes, harness roster) run in parallel as backgrounded subshells. Wall time ~5–8 s vs ~8 s sequential. Sub-agents read `docs/evidence/<id>/context-bundle.md` instead of each running its own `git log` / `ls` / `find`.
- **`scripts/compact-report.sh`** (NEW) — compresses a sub-agent's free-form output into a single structured JSON report at `<evidence-dir>/compact-report.json`. Schema: `{agent, branch, commit, files, test, blockers, evidence_paths, evidence_size_bytes, report_md, generated_at}`. Auto-detects commit SHA, file count (`git diff --name-only base...HEAD`), and test status from `test-results/*` (FAIL wins over PASS). Coordinator parses 200 bytes instead of re-reading 20 KB of implementation narrative.
- **`references/context-bundle.md`** (NEW) — pattern doc for the bundle: what goes in each section, failure modes, reproducibility, when to use.
- **`references/compact-report.md`** (NEW) — pattern doc for the compact report: output schema, auto-detection rules, decision order.

### Changed

- **`workflows/01-feature-delivery.md` Phase 3** — split into 3.0 (Bundle context) and 3.1 (Spawn Owner). Step 3.0 calls `scripts/context-bundle.sh` once and writes to `docs/evidence/<id>/context-bundle.md`. Step 3.1 (after Owner finishes) calls `scripts/compact-report.sh`.
- **`SKILL.md`** — references list updated to include `context-bundle.md` and `compact-report.md`.

### Why v1.2.0 (not v1.1.1)

Two new scripts + two new reference docs + a workflow change. Per D-006, install-behavior changes are patch, but **net-new scripts that change how the harness operates** are closer to minor. v1.2.0 signals "this is a new capability" rather than "behaviour tweak".

### Files changed

```
+ scripts/context-bundle.sh                  NEW (parallel context dump)
+ scripts/compact-report.sh                  NEW (structured JSON report)
+ references/context-bundle.md               NEW (pattern doc)
+ references/compact-report.md               NEW (pattern doc)
M  workflows/01-feature-delivery.md          Phase 3 split (3.0 bundle, 3.1 spawn)
M  SKILL.md                                  references list updated
M  meta.json                                 version: 1.1.0 → 1.2.0
M  skills/build-agent-app/meta.json          version: 1.1.0 → 1.2.0
M  CHANGELOG.md                              This entry
```

### Upgrade

```bash
npx -y skills update lora-sys/ai-engineering-harness -g
```

### How to use

```bash
# Once per Issue, in Phase 3.0
bash scripts/context-bundle.sh \
  --out docs/evidence/<id>/context-bundle.md

# Once per Owner Agent, after it finishes
bash scripts/compact-report.sh \
  --evidence-dir docs/evidence/<id> \
  --branch feature/<id>-<slug> \
  --agent <backend|frontend|qa|...> \
  --blocker "needs review from security-reviewer"
```

## [1.1.0] - 2026-07-13

New capability: SessionStart hook that auto-reads `.claude/SESSION.md` and injects it as context on every new Claude Code session. Read-only — the hook never writes to SESSION.md.

### Added
- **`hooks/session-start-read-session-md.sh`** (NEW) — the actual hook script. Reads `.claude/SESSION.md` from CWD; if it exists and is non-empty, prints the contents to stdout (which Claude Code injects as session context). Defence-in-depth: rejects symlinks that resolve outside CWD; caps at 64 KB with an advisory; exits 0 even on errors (never blocks the session).
- **`scripts/install-session-hook.sh`** (NEW) — idempotent installer. `--target global` writes to `~/.claude/settings.json`; `--target project` writes to `./.claude/settings.json`. `--dry-run` shows what would change. `--uninstall` removes only the hook entries (preserves other hooks). Atomic write via Python `os.replace` so a crash never wipes the user's settings.json.
- **`references/session-start-hook.md`** (NEW) — pattern doc covering the protocol, security notes, install/uninstall steps, and compatibility table.
- **`workflows/00-project-bootstrap.md`** — Step 11 added: optional SessionStart hook install (host-level change, opt-in, not part of default bootstrap).

### Changed
- **`SKILL.md`** — references list updated to include `session-start-hook.md`.

### Why v1.1.0 (not v1.0.11)

This is a clearly new capability (new script + new reference + new bootstrap step + new hook). Per D-006, install-behavior changes are patch-level, but a NEW install option for a NEW hook is closer to "structural" than "behavior tweak". Bumping to v1.1.0 (minor) signals to downstream consumers that there's new functionality to discover.

### Files changed

```
+ hooks/session-start-read-session-md.sh     NEW (read-only hook script)
+ scripts/install-session-hook.sh            NEW (idempotent installer)
+ references/session-start-hook.md           NEW (pattern doc)
M  workflows/00-project-bootstrap.md         Step 11 added (opt-in install)
M  SKILL.md                                  references list updated
M  meta.json                                 version: 1.0.10 → 1.1.0
M  skills/build-agent-app/meta.json          version: 1.0.10 → 1.1.0
M  memory/notes-2026-07-12.md                D-014 ("Atomic write inside Python + bash mv outside" is a footgun)
M  CHANGELOG.md                              This entry
```

### Upgrade

```bash
npx -y skills update lora-sys/ai-engineering-harness -g
# Then optionally install the hook:
bash /path/to/ai-engineering-harness/scripts/install-session-hook.sh --target global
```

## [1.0.10] - 2026-07-12

Post-release documentation roll-up. No user-facing behavior change; the runtime-visible files (SKILL.md, agents/, workflows/, scripts/, references/) are unchanged from v1.0.9.

### Added
- **`memory/notes-2026-07-12.md` D-013** — *"meta.json must match the tag being cut, not the previous tag"*. Documents the release-process anti-pattern that forced the v1.0.4 → v1.0.9 back-fill chain. The validator added in v1.0.5 catches this drift at release time; D-013 records the rule so future maintainers don't repeat the mistake.
- **`CHANGELOG.md`** — retrospective entries for v1.0.8 and v1.0.9 (the back-fill chain that didn't have proper CHANGELOG entries at the time).

### Files changed

```
M  meta.json                            1.0.9 → 1.0.10
M  skills/build-agent-app/meta.json     1.0.9 → 1.0.10
M  CHANGELOG.md                         This entry
M  memory/notes-2026-07-12.md           (already in main, this release rolls up the D-013 commit)
```

### Why v1.0.10 (not skipping until next functional release)

Cutting a release tag right after a docs-only commit lets `git describe` report `v1.0.10` cleanly on the checkout, instead of `v1.0.9-2-g3f64fe4` which mixes the tag with the post-release doc commits. Cleaner state for downstream consumers (skill indexes, `npx skills` cache invalidation, etc.).

## [1.0.9] - 2026-07-12

meta.json finally self-consistent. Bumped to `1.0.9` in the v1.0.9 commit (matching the new tag).

## [1.0.8] - 2026-07-12

Sigh — same pattern. meta.json bumped to `1.0.7` in the v1.0.8 commit (should have been `1.0.8`). I am writing this in real time as a reminder that the only thing that fixes this is bumping meta.json to the SAME version as the tag being cut, not the previous tag's version. v1.0.9 does that.

## [1.0.7] - 2026-07-12

One last meta.json bump. Sorry for the noise.

### Fixed
- **`meta.json` (both skills)** — bumped to `1.0.6`. The v1.0.6 release tagged `7741369` still claimed `1.0.5` (the previous version before v1.0.6 was cut). This release finally closes the loop: a fresh `git checkout v1.0.7` produces a clean `OK: 0 warning(s)` smoke test.

### Pattern note (for future maintainers)

The release-process anti-pattern I kept hitting:

> When bumping validator-relevant fields in commit X, the meta.json bump must match the **tag** that will be cut **after** commit X lands, not the tag that was current **before** commit X.

Concretely: the v1.0.5 commit added a smarter validator. To release v1.0.5 cleanly, meta.json should have been bumped to `1.0.5` (matching the new tag), not `1.0.4` (the version of the previous tag). I did the latter, which forced v1.0.6 → v1.0.7 back-fills.

The fix going forward: when committing changes that will become a new tag N, bump meta.json to `N` in that commit. The validator's drift check will then pass on the new checkout.

### Files changed

```
M  meta.json                            1.0.5 → 1.0.6
M  skills/build-agent-app/meta.json     1.0.5 → 1.0.6
M  CHANGELOG.md                         This entry
```

## [1.0.6] - 2026-07-12

Back-fill: meta.json version to match v1.0.5.

### Fixed
- **`meta.json` (both skills)** — bumped to `1.0.5`. The v1.0.5 release added the smarter drift-detection validator but did not bump the `meta.json` version field, so the v1.0.5 checkout still shows a drift warning. This is the last back-fill; v1.0.6 is purely a release-process correction.

### Files changed

```
M  meta.json                            1.0.4 → 1.0.5
M  skills/build-agent-app/meta.json     1.0.4 → 1.0.5
M  CHANGELOG.md                         This entry
```

## [1.0.5] - 2026-07-12

Validator enhancement: stop firing the "drift" warning on cleanly-checked-out older tags. Plus back-fill meta.json version drift from v1.0.3.

### Fixed
- **`meta.json` (both skills)** — bumped to `1.0.4`. (v1.0.4 itself shipped with `1.0.3` — same oversight as v1.0.3.)
- **`scripts/validate-meta.sh`** — smarter drift detection. Previously the check was `meta.json.version != latest_tag.version`, which would always fire on older checkouts AND on every release until meta.json was bumped in the same commit as the tag. Now: if `git describe --tags --exact-match HEAD` succeeds (i.e., HEAD is exactly at a tagged commit), compare to **that tag** instead of the latest one. Net effect:
  - `git checkout v1.0.4` with `meta.json` claiming `1.0.4` → no warning.
  - `git checkout v1.0.3` (which has a known self-inconsistency) → still warns, correctly, because the v1.0.3 release genuinely shipped with `meta.json` claiming `1.0.2`.
  - On `main` between releases (HEAD is not at any tag) → compares to latest tag, fires when you've bumped the validator-relevant fields without yet tagging.

### Files changed

```
M  meta.json                            1.0.3 → 1.0.4
M  skills/build-agent-app/meta.json     1.0.3 → 1.0.4
M  scripts/validate-meta.sh             Smarter drift check (uses checked-out tag)
M  CHANGELOG.md                         This entry
```

### Why v1.0.5 (not v1.0.4-patch)

v1.0.4 is already released. Re-tagging would not propagate. v1.0.5 carries the same patch-bump reasoning per D-006: no description change, no install command change, no routing-affecting change.

## [1.0.4] - 2026-07-12

Two follow-up fixes found during the v1.0.3 post-update smoke test on this machine. Pure tooling; no user-facing behavior change.

### Fixed
- **`meta.json` (both skills)** — bumped `version` from `1.0.2` to `1.0.3`. The v1.0.3 release shipped with `meta.json` still claiming `1.0.2`, which the new validator's drift check correctly flagged when run against the v1.0.3 checkout. This was a release-process oversight (the version field was added in v1.0.3 itself, so the bumped value should have been set to `1.0.3` not `1.0.2`). Apologies for the noise.
- **`scripts/check-templates.sh`** + **`scripts/validate-meta.sh`** + **`scripts/changelog.sh`** — all three used `cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"` or pure relative paths. When invoked from a foreign cwd (e.g., from `/home/lora` when the script lives in `~/.codex/skills/.../scripts/`), the `git rev-parse` fallback to `pwd` would land in a directory where the templates/meta.json couldn't be found, and the check would fail with confusing errors. Replaced with `cd "$(dirname "${BASH_SOURCE[0]}")/.."` so each script reliably lands in its own repo root regardless of how it was invoked.

### Files changed

```
M  meta.json                            version: 1.0.2 → 1.0.3
M  skills/build-agent-app/meta.json     version: 1.0.2 → 1.0.3
M  scripts/check-templates.sh           SCRIPT_DIR-based cd
M  scripts/validate-meta.sh             SCRIPT_DIR-based cd
M  scripts/changelog.sh                 SCRIPT_DIR-based cd
M  CHANGELOG.md                         This entry
```

### Why v1.0.4 (not v1.0.3-patch)
v1.0.3 is already released and immutable in users' hands. Re-tagging would not propagate. v1.0.4 carries the same patch-bump reasoning per D-006: no description change, no install command change, no routing-affecting change.

## [1.0.3] - 2026-07-12

Tooling hardening: three guards that close the three highest-frequency release-process regressions. No user-facing behavior change; meta.json now carries an explicit `version` field discoverable by indexers.

### Added
- **`scripts/check-templates.sh`** (NEW) — asserts required headings exist at start-of-line in `templates/*.md`. Currently 15 assertions covering PR description, evidence pack, implementation plan, review report, issue templates, ADR, and phase summary. Fast awk-based check (no regex meta-char escaping). Catches phantom edits like the v1.0.2 `## CI` regression that landed without `git diff` confirming it. Exit non-zero on missing required heading.
- **`meta.json` (both skills)** — added `"version": "1.0.2"` field. Indexers that walk meta.json can now surface the version without scraping `git tag`.

### Changed
- **`scripts/changelog.sh`** — added overwrite guard. If `CHANGELOG.md` already has a `## [X.Y.Z]` versioned entry, the script REFUSES to run (exit 2, message directs to `changelog-auto.sh --append` or `--force`). This prevents the bug where running the low-level generator would silently clobber a hand-edited changelog with `[Unreleased]`. Only `--force` bypasses, and only intentionally.
- **`scripts/validate-meta.sh`** — three new checks:
  1. `version` is now REQUIRED in `meta.json`. Format-validated against semver `X.Y.Z[-prerelease]`.
  2. Drift check: meta.json's `version` is compared to the latest `v*.*.*` git tag; mismatch → warning.
  3. **D-006 enforcement**: if `description` changed between two adjacent versioned tags AND only patch bumped, warn (description is routing surface, should bump minor per D-006).
- **`CONTRIBUTING.md`** — PR-process step 4 now requires both `validate-meta.sh --strict` AND `check-templates.sh --strict` to pass before commit.
- **`memory/notes-2026-07-12.md`** — added D-012 ("Tooling hardening: catch regressions before they ship") documenting the three guards and their motivation.

### Why v1.0.3 (not v1.1.0)
- The user-facing skill `description` is unchanged.
- The install commands are unchanged.
- The harness triggers on the same queries.
- The new tooling is invisible to runtime users (only maintainers see it).
- Per D-006 (routing-affecting → minor, structural → major, everything else → patch), this is a **patch bump**.

### Files added / changed

```
+ scripts/check-templates.sh            NEW template assertion check
M  scripts/changelog.sh                 Added overwrite guard (exit 2 + --force)
M  scripts/validate-meta.sh             version required + drift + D-006 enforcement
M  meta.json                            Added "version": "1.0.2"
M  skills/build-agent-app/meta.json     Added "version": "1.0.2"
M  CONTRIBUTING.md                      PR-process step 4 + "When in doubt" updated
M  memory/notes-2026-07-12.md           D-012 added
M  CHANGELOG.md                         This entry
```

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
