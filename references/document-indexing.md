# Document Indexing

The harness treats docs as a discoverable index, not a tree to walk.

## Required Files

```
docs/
├── INDEX.md                              # master
└── .index/
    ├── manifest.json                     # all docs, with IDs, types, owners
    ├── relations.json                    # doc-to-doc edges
    └── freshness.json                    # last-touched dates vs use frequency
```

## manifest.json Schema (sketch)

```json
{
  "docs": [
    {
      "id": "docs/product/prd.md",
      "type": "product|architecture|design|decision|evidence|adr|session",
      "title": "...",
      "summary": "...",
      "owner": "...",
      "updated": "YYYY-MM-DD",
      "supersedes": ["..."],
      "superseded_by": null,
      "applicable_agents": ["frontend", "backend"],
      "tags": ["..."]
    }
  ]
}
```

## Operations

- **Add / edit / move / delete** — propagate the change.
- **Promote** — when a doc becomes Source of Truth, mark `so_of_truth: true`. When a doc is stale, mark `status: stale` (do not delete blindly).
- **Relations** — ADRs cite docs; docs cite ADRs; modules cite phases; phases cite Evidence dirs. Maintain bidirectional edges.

## Maintenance

- A Codex hook or `scripts/refresh-index.sh` rebuilds the index when docs change.
- A nightly / pre-PR step fails if a doc is referenced but missing from `manifest.json`.
- Stale docs (>90 days without a tagged owner update + not on the hot path) get flagged in `freshness.json`.

