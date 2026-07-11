# Security Acceptance Checklist

Used by `security-reviewer` and as a self-check for sensitive changes.

- [ ] Threat model recorded for new trust boundary or sensitive data flow.
- [ ] Secrets not in code, tests, or logs; `gitleaks` clean.
- [ ] Dependency audit (`npm audit`, `pip-audit`, etc.) clean or risk-accepted with ADR.
- [ ] Auth: tokens rotated, refresh logic correct, session invalidation tested.
- [ ] Authz: negative cases tested for every role boundary touched.
- [ ] Input validation at trust boundary (server endpoints, third-party webhooks).
- [ ] Output encoding / parameterization where user-controlled data flows in.
- [ ] CSRF / SSRF / path traversal negative cases tested where applicable.
- [ ] Sensitive data not logged; PII redaction verified.
- [ ] CORS / CSP / headers unchanged or intentionally updated with rationale.
- [ ] Supply-chain: pinned hashes / versions for downloaded artifacts.
- [ ] Backups + RPO/RTO documented for data-touching changes.

