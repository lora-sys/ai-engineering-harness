# Backend Acceptance Checklist

Owner signs every relevant box before opening PR.

## API Design

- [ ] Resource naming is consistent with existing routes.
- [ ] Methods + paths map cleanly to user actions.
- [ ] Status codes correct (no 200 for errors; no 500 for client errors).
- [ ] Error response shape consistent across endpoints.

## Validation

- [ ] Every input validated (type, range, length, character allow-list).
- [ ] Errors return a machine-readable code and a human message.

## Auth & Authz

- [ ] Auth required by default; explicit allow-list for public endpoints.
- [ ] Authz enforced server-side (no client-supplied role claim).
- [ ] Tests cover forbidden cases (no token, wrong role, expired).

## Persistence

- [ ] DB access via repository; no SQL in handlers.
- [ ] Migrations exist; additive when possible.
- [ ] Transactions for multi-write consistency.

## Reliability

- [ ] Idempotency keys handled where the operation is non-idempotent.
- [ ] Retries idempotent and bounded.
- [ ] Timeouts on every external call.
- [ ] Circuit breakers / fallbacks for external deps.

## Observability

- [ ] Structured logs with correlation id.
- [ ] Metric(s) emitted for the operation.
- [ ] Health-check impact considered.

## Performance

- [ ] Hot-path benchmarked; p95 budget recorded.

