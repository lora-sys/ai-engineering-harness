# Workflow — Adversarial PR Review

Mandatory per PR. The goal is to surface latent defects, not confirm the implementer's narrative.

## Step 1 — Pick Reviewers

Default (every PR):

- **Bug Hunter** — runtime defects.
- **Behavior Reviewer** — spec adherence.

Add if any of:

- Diff > ~300 lines or touches ≥3 modules → **Architecture Reviewer**.
- Touches auth / payments / PII / secrets / deps / infra → **Security Reviewer**.
- Touches UI (any component, route, or style) → **UI Reviewer**.

Document the chosen set on the PR.

## Step 2 — Cold Start Each Reviewer

Each reviewer is a **fresh context**. The Coordinator loads only:

- The PR diff (full).
- The Issue body.
- The Implementation Plan file.
- The Evidence directory.
- The relevant ADR (if any) and `docs/architecture/<module>.md`.
- The role's checklist.

It must **not** load the implementer's chat history, debug logs, or "I tried X because Y" explanations.

## Step 3 — Output

Each reviewer writes `docs/evidence/<id>/review-<role>.md` following its agent file template. Posts a short summary on the PR.

## Step 4 — Aggregator

`review-aggregator.md` writes `docs/evidence/<id>/fix-tasks.md` with prioritized, de-duplicated tasks.

## Step 5 — Loop

Loop Coordinator → Owner (with fix list) → re-test → re-review until Aggregator reports ✅ Approved (no Critical/High open).

## Step 6 — Sign-off

Coordinator records review sign-off in `PROJECT_STATUS.md` and on the PR thread.

## Anti-Patterns the Workflow Refuses

- Reviewer using the implementer's chat to "fill in missing context" — defeats cold start.
- A single reviewer covering two roles.
- Reviewer marking PASS because tests already exist (tests can lie).
- Coordinator approving without aggregating.

