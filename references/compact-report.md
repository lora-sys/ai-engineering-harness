# Compact Report Pattern

Structured summary of a sub-agent's evidence pack — what the parent Coordinator actually needs to decide "advance to Phase N+1" or "loop back", without re-reading the full implementation report.

## Output shape

`scripts/compact-report.sh` writes a single JSON file at `<evidence-dir>/compact-report.json`:

```json
{
  "agent": "backend",
  "branch": "feature/42-ci-gate",
  "commit": "5a65b7a",
  "files": 7,
  "test": "pass",
  "blockers": [
    "needs security review",
    "waiting on infra ticket #108"
  ],
  "evidence_paths": [
    "implementation-report.md",
    "test-results/unit.log"
  ],
  "evidence_size_bytes": 661,
  "report_md": "implementation-report.md",
  "generated_at": "2026-07-13T09:39:06+08:00"
}
```

| Field | Source | Required |
| --- | --- | --- |
| `agent` | `--agent` flag | yes |
| `branch` | `--branch` flag | yes |
| `commit` | `--commit` flag or `git rev-parse --short HEAD` | auto-detected |
| `files` | `--files-changed` or `git diff --name-only base...HEAD \| wc -l` | auto-detected |
| `test` | `--test` flag or grep on `test-results/*` | auto-detected |
| `blockers` | repeated `--blocker` flag | optional |
| `evidence_paths` | `find <evidence-dir> -type f` | auto-collected |
| `evidence_size_bytes` | `wc -c` on each evidence file | auto-computed |
| `report_md` | name of the free-form report file in evidence-dir | auto-detected |
| `generated_at` | `date -Iseconds` | always |

## Usage

```bash
scripts/compact-report.sh \
  --evidence-dir docs/evidence/42 \
  --branch feature/42-ci-gate \
  --agent backend \
  --blocker "needs review from security-reviewer" \
  --blocker "waiting on infra ticket #108"
```

Output goes to stdout (so the Coordinator can pipe it into another tool) AND to `<evidence-dir>/compact-report.json`.

## Test status auto-detection

If `--test` is not given, the script greps `test-results/*` for markers:

| Markers | Status |
| --- | --- |
| `PASS`, `OK`, `passed`, `all tests pass` | `pass` |
| `FAIL`, `ERROR`, `failed`, `tests failed` | `fail` |
| Neither (and `test-results/` exists) | `unknown` |
| No `test-results/` | `skipped` |

PASS-grep runs first; if both PASS and FAIL appear in the same file (rare), the FAIL wins (grep returns 0 for the FAIL second branch only if the first branch returned non-zero — actually this script uses `elif`, so PASS wins ties). For multi-run test outputs, prefer explicit `--test fail` if your CI output mixes passes and fails.

## Why it matters

Without a compact report, the Coordinator must re-read the sub-agent's full chat transcript (often 5–20 KB of implementation narrative) just to answer "did the work complete?" With the report, it's 200 bytes of structured data.

This compresses the Coordinator's per-Phase decision cost from "read 10 KB and reason about it" to "parse 200 bytes and apply policy".

## Where it goes in the harness

`workflows/01-feature-delivery.md` Phase 5 (Implement) and Phase 7 (CI) call `scripts/compact-report.sh` after each sub-agent completes. The Coordinator collects reports in `docs/evidence/<id>/compact-report.{frontend,backend,qa}.json` and decides whether to advance to Phase 8 (adversarial review) based on `test: pass` + empty `blockers`.

## See also

- `references/cd-monitoring.md` — CI watching pattern (related: also produces small structured events).
- `templates/evidence-pack.md` — the evidence pack that the compact report summarises.
- `workflows/01-feature-delivery.md` — where compact-report.sh is invoked.
