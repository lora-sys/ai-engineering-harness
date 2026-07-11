# Shell & Tooling Shortcuts

Stable, repeated patterns the harness relies on. The Coordinator can run these without prompting.

## Repo Discovery

```bash
git ls-files | wc -l
git log --oneline -20
ls docs/ 2>/dev/null || echo "NO_DOCS"
```

## Document Index Refresh

```bash
scripts/refresh-index.sh
```

## New Session / Evidence Dir

```bash
scripts/new-session.sh <issue-id>
scripts/new-evidence.sh <issue-id>
```

## Worktree

```bash
scripts/new-worktree.sh <issue-id> <slug>
```

## Test & Verify

```bash
npm test || pnpm test || pytest -q  # whichever applies
agent-browser screenshot <url> out.png 1440x900
playwright test --reporter=json
```

## Adversarial Review Spawn (template)

The Coordinator fills in `agents/scope.md` template, then spawns via:

```bash
# (illustrative — actual spawn depends on host)
spawn_agent review-<role> --prompt "$(cat prompt.md)" --issue <id>
```

