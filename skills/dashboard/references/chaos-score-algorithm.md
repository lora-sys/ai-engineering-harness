# Chaos Score Algorithm

The Takeover Audit view computes a **Chaos Score** from 0 to 100. Higher = more chaos (worse project health). Lower = cleaner, more maintainable project.

## Scoring Rules

Start at **100 points**. Subtract for each issue found.

### Deductions by Category

| Category | Check | Deduction | Max deduction |
|----------|-------|-----------|---------------|
| **Evidence** | Evidence pack missing required files (verification.md, test-results) | -5 per pack | -20 |
| **Evidence** | No screenshots in a UI evidence pack | -3 per pack | -15 |
| **Evidence** | AC verification has FAIL entries | -5 per FAIL | -30 |
| **Review** | Evidence pack has no reviewer reports | -5 per pack | -20 |
| **Review** | Reviewer report has Blocking findings | -5 per finding | -25 |
| **Review** | Reviewer report has High findings | -3 per finding | -15 |
| **Documentation** | PROJECT_STATUS.md missing or empty | -10 | -10 |
| **Documentation** | Memory directory empty or missing | -5 | -5 |
| **Documentation** | Freshness file stale (> 30 days) | -5 | -5 |
| **Testing** | No test results in any evidence pack | -5 | -5 |
| **Testing** | All test results show 0 tests | -5 | -5 |
| **CI/CD** | CI status reported as red | -10 | -10 |
| **Blocked** | Issues in Blocked section with no resolution | -3 per item | -15 |

### Grade Mapping

| Score | Grade | Meaning |
|-------|-------|---------|
| 90-100 | A | Excellent — ready for production |
| 75-89 | B | Good — minor issues to address |
| 60-74 | C | Fair — significant cleanup needed |
| 40-59 | D | Poor — major refactoring required |
| 0-39 | F | Critical — project is in disarray |

### Algorithm Pseudocode

```javascript
function computeChaosScore(projectStatus, evidencePacks, memory, freshness) {
  let score = 100;
  const issues = [];
  const bySeverity = { critical: 0, high: 0, medium: 0, low: 0 };
  const byCategory = {};

  function addIssue(severity, category, description, file, line) {
    score = Math.max(0, score - deductionFor(severity));
    issues.push({ severity, category, description, file, line });
    bySeverity[severity]++;
    byCategory[category] = (byCategory[category] || 0) + 1;
  }

  // Evidence checks
  for (const pack of evidencePacks) {
    if (!pack.hasVerification) {
      addIssue('medium', 'evidence', `Pack #${pack.id} missing verification.md`, pack.path);
    }
    if (pack.isUI && !pack.hasScreenshots) {
      addIssue('low', 'evidence', `Pack #${pack.id} missing screenshots`, pack.path);
    }
    if (pack.hasFailures) {
      addIssue('high', 'evidence', `Pack #${pack.id} has FAIL entries in AC`, pack.path);
    }
    if (!pack.hasReviews) {
      addIssue('medium', 'review', `Pack #${pack.id} has no reviewer reports`, pack.path);
    }
    for (const finding of pack.findings) {
      if (finding.severity === 'blocking') {
        addIssue('critical', 'review', `Blocking finding in ${pack.id}: ${finding.description}`, finding.file, finding.line);
      } else if (finding.severity === 'high') {
        addIssue('high', 'review', `High finding in ${pack.id}: ${finding.description}`, finding.file, finding.line);
      }
    }
  }

  // Documentation checks
  if (!projectStatus || !projectStatus.now) {
    addIssue('high', 'documentation', 'PROJECT_STATUS.md missing or empty', 'PROJECT_STATUS.md');
  }
  if (!memory || memory.length === 0) {
    addIssue('low', 'documentation', 'Memory directory is empty or missing', 'memory/');
  }
  if (freshness && isStale(freshness.lastSync, 30)) {
    addIssue('low', 'documentation', 'Documentation freshness file is stale (>30 days)', 'docs/.index/freshness.json');
  }

  // Testing checks
  const hasTestResults = evidencePacks.some(p => p.testResultCount > 0);
  if (!hasTestResults) {
    addIssue('medium', 'testing', 'No test results found in any evidence pack', 'docs/evidence/');
  }

  // Blocked issues
  if (projectStatus && projectStatus.blocked) {
    for (const item of projectStatus.blocked) {
      addIssue('medium', 'blocked', `Blocked: ${item.title} — waiting for ${item.blockedOn}`, 'PROJECT_STATUS.md');
    }
  }

  // CI
  if (projectStatus && projectStatus.health && projectStatus.health.ci === 'red') {
    addIssue('high', 'ci', 'CI is red', 'PROJECT_STATUS.md');
  }

  const grade = score >= 90 ? 'A' : score >= 75 ? 'B' : score >= 60 ? 'C' : score >= 40 ? 'D' : 'F';
  return { chaosScore: score, maxScore: 100, grade, issues, bySeverity, byCategory };
}
```

### Deduction by Severity

| Severity | Deduction |
|----------|-----------|
| Critical | -10 |
| High | -5 |
| Medium | -3 |
| Low | -1 |

### Display in Dashboard

The Takeover Audit view shows:
1. **Chaos Score gauge** — large SVG arc, color-coded (green → yellow → red)
2. **Grade letter** — A/B/C/D/F, large
3. **Severity breakdown** — bar chart showing critical/high/medium/low counts
4. **Category breakdown** — horizontal bars showing issues per category
5. **Issue list** — filterable table with severity, category, description, file link
