```markdown
# ai-engineering-harness Development Patterns

> Auto-generated skill from repository analysis

## Overview

This skill provides a comprehensive guide to contributing to the `ai-engineering-harness` TypeScript codebase. It covers coding conventions, documentation and testing patterns, and outlines the key workflows for maintaining consistent, high-quality documentation and code structure. The repository emphasizes robust documentation practices, count consistency, and markdown structure validation, ensuring clarity and maintainability across multilingual documentation.

## Coding Conventions

### File Naming

- Use **PascalCase** for file names.
  - Example: `ChaosScoreAlgorithm.ts`, `QuickStart.md`

### Import Style

- Use **relative imports** for modules within the project.
  - Example:
    ```typescript
    import { ChaosScoreAlgorithm } from './skills/dashboard/references/ChaosScoreAlgorithm';
    ```

### Export Style

- Use **named exports** for all modules.
  - Example:
    ```typescript
    export function calculateChaosScore(data: DataType): number {
      // implementation
    }
    ```

### Commit Messages

- Follow **conventional commit** patterns.
  - Prefixes: `docs`, `test`, etc.
  - Example:
    ```
    docs: update README structure for new workflow
    test: add tests for chaos score algorithm
    ```

## Workflows

### Documentation Sync and Structure Update

**Trigger:** When documentation structure or content needs to be updated, reordered, or synced across languages (e.g., after a major doc rewrite or feature addition).  
**Command:** `/sync-docs`

1. Identify outdated, duplicated, or stale sections in main README(s) and related docs.
2. Delete or relocate obsolete content (e.g., move maintainer-facing sections to `CONTRIBUTING.md`).
3. Reorder sections to match a canonical or issue-specified structure.
4. Update section headings to consistent levels for TOC generation.
5. Normalize counts (workflows, references, examples, install targets, etc.) using invisible count markers:
    ```markdown
    <!-- count:workflows=3 -->
    ```
6. Fix dead or incorrect internal anchors and links.
7. Sync changes to translated/secondary documentation (e.g., `README_EN.md`), including translating new or changed sections.
8. Verify all relative links, anchors, and rendered elements (tables, images) work as intended.
9. Reference or close related issues (e.g., `#11`).

### Documentation Counts Consistency Update

**Trigger:** When the number of workflows, tests, examples, or other counted items changes, or when inconsistencies are found between files.  
**Command:** `/update-counts`

1. Identify all locations in documentation where counts are referenced.
2. Update counts in all relevant files to match the actual state of the repo.
3. Add or update invisible `<!-- count:key -->` markers for machine-checking.
    ```markdown
    <!-- count:examples=5 -->
    ```
4. Verify that no count drift remains between files.
5. Optionally, update related descriptions or tables to reflect the new numbers.
6. Run or update `scripts/check-templates.sh` to validate counts.

### Add or Fix Markdown Structure CI Gate

**Trigger:** When a markdown rendering bug is discovered or when new doc structure rules are needed.  
**Command:** `/add-markdown-ci-gate`

1. Create or update a shell script (e.g., `scripts/check-templates.sh`) to check for:
    - Fence parity
    - Heading levels inside fences
    - Invisible count markers
2. Add or update bats tests (e.g., `tests/check-templates.bats`) to cover new rules or edge cases.
3. Integrate the script into CI (e.g., `test.yml` static job).
4. Test the script by running it on current and previous versions of the docs to ensure it catches real issues and avoids false positives.
5. Document the new checks and ensure contributors are aware of the gate.

#### Example: Shell Script Snippet for Markdown Check

```sh
#!/bin/bash
# scripts/check-templates.sh

grep -r --include="*.md" "<!-- count:" . | while read -r line; do
  # Check for count marker format
  if ! [[ $line =~ <!--\ count:[a-zA-Z0-9_-]+=([0-9]+)\ --> ]]; then
    echo "Invalid count marker: $line"
    exit 1
  fi
done
```

## Testing Patterns

- Test files follow the `*.test.*` naming convention.
  - Example: `ChaosScoreAlgorithm.test.ts`
- Testing framework is not explicitly specified; ensure tests are colocated and named appropriately.
- Test scripts and CI integration may use shell scripts and bats for markdown/documentation validation.

## Commands

| Command                | Purpose                                                                                   |
|------------------------|-------------------------------------------------------------------------------------------|
| /sync-docs             | Synchronize documentation structure and content across all relevant files and languages.   |
| /update-counts         | Update and verify all documentation count markers for consistency.                        |
| /add-markdown-ci-gate  | Add or update CI checks for markdown structure, heading levels, and count markers.        |
```