# Database Acceptance Checklist

Owner signs every relevant box before opening PR.

- [ ] Migration has both `.up.sql` and `.down.sql`.
- [ ] Migration is idempotent on re-run.
- [ ] Index added with `CONCURRENT` where supported.
- [ ] No `SELECT *` in stored procedures; explicit columns.
- [ ] Constraints explicit (NOT NULL, FK, CHECK) — never rely on app-side validation alone.
- [ ] Locks held during migration measured + below agreed threshold.
- [ ] Pre/post row-count + sample row snapshots in `docs/evidence/<id>/db/`.
- [ ] Rollback rehearsed end-to-end on staging.
- [ ] Backfill plan documented when data is reshaped.

