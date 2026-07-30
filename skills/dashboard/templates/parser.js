#!/usr/bin/env node
/**
 * Dashboard Parser + Server
 *
 * Zero-dependency Node.js HTTP server that scans a harness-managed project
 * and serves a JSON API + dashboard HTML.
 *
 * Usage:
 *   node parser.js                    # serve on :4321
 *   PORT=8080 node parser.js          # custom port
 *   node parser.js --static-only      # only serve static files (no API)
 *
 * API:
 *   GET /                     → dashboard.html
 *   GET /api/health           → project health summary
 *   GET /api/project-status   → full PROJECT_STATUS.md parsed
 *   GET /api/evidence         → all evidence pack summaries
 *   GET /api/evidence/:id     → full detail for one pack
 *   GET /api/memory           → memory summary
 *   GET /api/kanban           → issues grouped by closed-loop stage
 *   GET /api/takeover-audit   → Chaos Score + categorized issues
 *   GET /api/screenshots/:id/:file → serve image from evidence pack
 *   GET /api/quick-scan          → vibe-signs heuristic scan (10 detectors, Issue #8 + #9)
 */

'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// ─── Configuration ────────────────────────────────────────────────────────────

const PORT = parseInt(process.env.PORT || process.env.DASHBOARD_PORT || '4321', 10);
const PROJECT_ROOT = findProjectRoot();
const DASHBOARD_DIR = path.join(PROJECT_ROOT, '.dashboard');
const EVIDENCE_DIR = path.join(PROJECT_ROOT, 'docs', 'evidence');
const MEMORY_DIR = path.join(PROJECT_ROOT, 'memory');
const FRESHNESS_FILE = path.join(PROJECT_ROOT, 'docs', '.index', 'freshness.json');
const STATUS_FILE = path.join(PROJECT_ROOT, 'PROJECT_STATUS.md');
const REFRESH_INTERVAL = 30000; // 30 seconds

// Directories to scan for vibe-signs (source code)
const SOURCE_DIRS = ['src', 'lib', 'app', 'server', 'pkg', 'internal', 'cmd'];
// File extensions to scan for vibe-signs
const SOURCE_EXTS = ['.ts', '.js', '.tsx', '.jsx', '.py', '.go', '.rs', '.java', '.rb', '.php'];

let dashboardHtml = '';
let parserTimestamp = Date.now();

// ─── Helpers ──────────────────────────────────────────────────────────────────

function findProjectRoot() {
  let dir = process.cwd();
  while (dir !== path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, 'PROJECT_STATUS.md'))) return dir;
    if (fs.existsSync(path.join(dir, 'CLAUDE.md'))) return dir;
    if (fs.existsSync(path.join(dir, 'AGENTS.md'))) return dir;
    if (fs.existsSync(path.join(dir, '.git'))) return dir;
    dir = path.dirname(dir);
  }
  return process.cwd();
}

function readFileSafe(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf-8');
  } catch {
    return null;
  }
}

function fileExists(filePath) {
  try {
    return fs.statSync(filePath).isFile();
  } catch {
    return false;
  }
}

function dirExists(dirPath) {
  try {
    return fs.statSync(dirPath).isDirectory();
  } catch {
    return false;
  }
}

function listDirSafe(dirPath) {
  try {
    return fs.readdirSync(dirPath);
  } catch {
    return [];
  }
}

function listAllFiles(dirPath) {
  const results = [];
  const items = listDirSafe(dirPath);
  for (const item of items) {
    const fullPath = path.join(dirPath, item);
    try {
      const stat = fs.statSync(fullPath);
      if (stat.isDirectory()) {
        results.push(...listAllFiles(fullPath));
      } else {
        results.push(fullPath);
      }
    } catch {
      // skip unreadable entries
    }
  }
  return results;
}

function meta(sources, missing) {
  return {
    generatedAt: new Date().toISOString(),
    projectRoot: PROJECT_ROOT,
    sources,
    missing
  };
}

function jsonResponse(res, statusCode, data) {
  const body = JSON.stringify(data, null, 2);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Cache-Control': 'no-cache, no-store, must-revalidate'
  });
  res.end(body);
}

function htmlResponse(res, statusCode, html) {
  res.writeHead(statusCode, {
    'Content-Type': 'text/html; charset=utf-8',
    'Cache-Control': 'no-cache, no-store, must-revalidate'
  });
  res.end(html);
}

function imageResponse(res, statusCode, filePath, contentType) {
  try {
    const data = fs.readFileSync(filePath);
    res.writeHead(statusCode, {
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=3600'
    });
    res.end(data);
  } catch {
    jsonResponse(res, 404, { error: 'Screenshot not found', _meta: meta([], [path.basename(filePath)]) });
  }
}

// ─── Markdown Parsers ─────────────────────────────────────────────────────────

function parseProjectStatus(content) {
  const result = {
    now: [],
    backlog: [],
    blocked: [],
    recentlyMerged: [],
    reviewerThreads: [],
    phases: [],
    health: {},
    risks: []
  };

  if (!content) return result;

  const lines = content.split('\n');
  let currentSection = null;
  let sectionContent = [];

  for (const line of lines) {
    const headingMatch = line.match(/^##\s+(.+?)(?:\s*—\s*(.+))?$/);

    if (headingMatch) {
      if (currentSection) {
        parseSection(currentSection, sectionContent, result);
      }
      currentSection = headingMatch[1].trim().toLowerCase();
      sectionContent = [];
    } else if (currentSection) {
      sectionContent.push(line);
    }
  }

  if (currentSection) {
    parseSection(currentSection, sectionContent, result);
  }

  return result;
}

function parseSection(section, lines, result) {
  // Normalize section name
  const sectionMap = {
    'now (in progress)': 'now',
    'now': 'now',
    'backlog': 'backlog',
    'blocked (waiting for approval / external)': 'blocked',
    'blocked': 'blocked',
    'recently merged': 'recentlyMerged',
    'open reviewer threads': 'reviewerThreads',
    'phase': 'phases',
    'health': 'health',
    'risks': 'risks'
  };

  const key = sectionMap[section];
  if (!key) return;

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#') || trimmed.startsWith('---')) continue;

    if (key === 'health') {
      // Parse key: value pairs
      const kvMatch = trimmed.match(/^-\s*(\w+):\s*(.+)$/);
      if (kvMatch) {
        result.health[kvMatch[1].toLowerCase()] = kvMatch[2].trim();
      }
      continue;
    }

    if (key === 'phases') {
      const phaseMatch = trimmed.match(/^-\s*(.+?)\s*[—\-]\s*(.+)$/);
      if (phaseMatch) {
        result.phases.push({ name: phaseMatch[1].trim(), status: phaseMatch[2].trim() });
      }
      continue;
    }

    if (key === 'risks') {
      if (trimmed.startsWith('- ')) {
        result.risks.push(trimmed.slice(2).trim());
      }
      continue;
    }

    // List items: parse key: value pairs from "- Title — key: value"
    const dashMatch = trimmed.match(/^-\s*(.+?)(?:\s*[—\-]\s*(.+))?$/);
    if (!dashMatch) continue;

    const title = dashMatch[1].trim();
    const rest = dashMatch[2] || '';

    const item = { title };

    // Extract key:value pairs
    const kvRegex = /(\w+):\s*([^,]+)/g;
    let m;
    while ((m = kvRegex.exec(rest)) !== null) {
      item[m[1].toLowerCase()] = m[2].trim();
    }

    // Special handling for reviewer threads
    if (key === 'reviewerThreads') {
      const reviewRegex = /(\w+):\s*(approved|non-blocking|blocking|unknown|\S+)/gi;
      while ((m = reviewRegex.exec(rest)) !== null) {
        item[m[1].toLowerCase()] = m[2].trim();
      }
    }

    result[key].push(item);
  }
}

function parseVerificationTable(content) {
  const rows = [];
  if (!content) return rows;

  const lines = content.split('\n');
  let inTable = false;

  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('|') && trimmed.includes('---')) {
      inTable = true;
      continue;
    }
    if (inTable && trimmed.startsWith('|')) {
      const cells = trimmed.split('|').filter((_, i, arr) => i > 0 && i < arr.length - 1);
      if (cells.length >= 4) {
        rows.push({
          id: cells[0]?.trim() || '',
          description: cells[1]?.trim() || '',
          method: cells[2]?.trim() || '',
          result: cells[3]?.trim() || '',
          evidence: cells[4]?.trim() || ''
        });
      }
    }
    if (inTable && !trimmed.startsWith('|') && trimmed !== '') {
      inTable = false;
    }
  }

  return rows;
}

function parseMarkdownHeadings(content) {
  if (!content) return { title: '', summary: '' };

  const lines = content.split('\n');
  let title = '';
  let summary = '';
  let foundTitle = false;

  for (const line of lines) {
    const headingMatch = line.match(/^#+\s+(.+)/);
    if (headingMatch && !title) {
      title = headingMatch[1].trim();
      foundTitle = true;
      continue;
    }
    if (foundTitle && line.trim() && !summary) {
      // Skip list markers and HTML comments
      const clean = line.replace(/^[-*]\s*/, '').replace(/<!--.*?-->/g, '').trim();
      if (clean) {
        summary = clean;
        break;
      }
    }
  }

  return { title, summary };
}

function extractCodeBlocks(content) {
  const blocks = [];
  if (!content) return blocks;

  const regex = /```(\w+)?\n?([\s\S]*?)```/g;
  let m;
  while ((m = regex.exec(content)) !== null) {
    blocks.push({
      language: m[1] || 'text',
      code: m[2].trim()
    });
  }

  return blocks;
}

function extractReviewFindings(content, role) {
  const findings = [];
  if (!content) return findings;

  // Look for severity table or bullet findings
  const severityMatch = content.match(/\*\*(Critical|High|Medium|Low)\*\*/g);
  const statusMatch = content.match(/Status:\s*(Approved|Non-blocking|Blocking|❌|✅|⚠️)/i);

  let status = 'unknown';
  if (statusMatch) {
    const s = statusMatch[1].toLowerCase();
    if (s.includes('approv')) status = 'approved';
    else if (s.includes('non-block') || s.includes('non_block')) status = 'non-blocking';
    else if (s.includes('block')) status = 'blocking';
  }

  // Parse table rows if present
  const lines = content.split('\n');
  let inTable = false;
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed.startsWith('|') && trimmed.includes('---')) {
      inTable = true;
      continue;
    }
    if (inTable && trimmed.startsWith('|')) {
      const cells = trimmed.split('|').filter((_, i, arr) => i > 0 && i < arr.length - 1);
      if (cells.length >= 4) {
        const sevMap = { 'critical': 'critical', 'high': 'high', 'medium': 'medium', 'low': 'low' };
        const sevText = (cells[0]?.trim() || '').toLowerCase();
        const severity = sevMap[sevText] || 'medium';
        findings.push({
          severity,
          category: cells[1]?.trim() || 'general',
          description: cells[2]?.trim() || '',
          file: cells[3]?.trim() || '',
          line: parseInt(cells[4]?.trim() || '0', 10) || null
        });
      }
    }
    if (inTable && !trimmed.startsWith('|') && trimmed !== '') {
      inTable = false;
    }
  }

  return { role, status, findings };
}

function parseTestResults(testDir, packId) {
  const results = {};
  const testFiles = ['unit.json', 'integration.json', 'e2e.json', 'api-trace.json'];

  for (const file of testFiles) {
    const filePath = path.join(testDir, file);
    const content = readFileSafe(filePath);
    if (!content) continue;

    try {
      const data = JSON.parse(content);
      const type = file.replace('.json', '');
      const passed = Array.isArray(data.passed) ? data.passed.length :
                     typeof data.passed === 'number' ? data.passed : 0;
      const failed = Array.isArray(data.failed) ? data.failed.length :
                     typeof data.failed === 'number' ? data.failed : 0;
      results[type] = { passed, failed, total: passed + failed };
    } catch {
      results[file.replace('.json', '')] = { passed: 0, failed: 0, total: 0 };
    }
  }

  return results;
}

// ─── Data Collectors ──────────────────────────────────────────────────────────

function collectProjectStatus() {
  const sources = [];
  const missing = [];

  if (!fileExists(STATUS_FILE)) {
    missing.push('PROJECT_STATUS.md');
    return { data: {}, sources, missing };
  }

  sources.push('PROJECT_STATUS.md');
  const content = readFileSafe(STATUS_FILE);
  const parsed = parseProjectStatus(content);

  // Parse health section for more detail
  if (parsed.health) {
    const healthContent = content.split('\n');
    const healthSection = [];
    let inHealth = false;
    for (const line of healthContent) {
      if (line.match(/^##\s+Health/)) { inHealth = true; continue; }
      if (inHealth && line.match(/^##/)) break;
      if (inHealth) healthSection.push(line);
    }

    // Extract CI, Tests, Docs, Memory status
    const healthResult = {};
    for (const line of healthSection) {
      const kvMatch = line.match(/-\s*(\w+):\s*(\S+)/);
      if (kvMatch) {
        healthResult[kvMatch[1].toLowerCase()] = kvMatch[2];
      }
    }
    parsed.health = { ...parsed.health, ...healthResult };
  }

  return { data: parsed, sources, missing };
}

function collectEvidencePacks() {
  const sources = [];
  const missing = [];
  const packs = [];

  if (!dirExists(EVIDENCE_DIR)) {
    missing.push('docs/evidence/');
    return { packs, sources, missing };
  }

  sources.push('docs/evidence/');

  const packDirs = listDirSafe(EVIDENCE_DIR).filter(d => {
    const fullPath = path.join(EVIDENCE_DIR, d);
    try { return fs.statSync(fullPath).isDirectory(); }
    catch { return false; }
  });

  for (const packId of packDirs) {
    const packDir = path.join(EVIDENCE_DIR, packId);
    const packSources = [];
    const packMissing = [];

    // Read verification.md
    const verificationPath = path.join(packDir, 'verification.md');
    const verificationContent = readFileSafe(verificationPath);
    const verification = parseVerificationTable(verificationContent);
    if (verificationContent) packSources.push(`evidence/${packId}/verification.md`);
    else packMissing.push(`evidence/${packId}/verification.md`);

    // Read change-summary.md
    const changeSummaryPath = path.join(packDir, 'change-summary.md');
    const changeSummaryContent = readFileSafe(changeSummaryPath);
    const changeSummary = parseMarkdownHeadings(changeSummaryContent);
    if (changeSummaryContent) packSources.push(`evidence/${packId}/change-summary.md`);
    else packMissing.push(`evidence/${packId}/change-summary.md`);

    // Read implementation-plan.md
    const planPath = path.join(packDir, 'implementation-plan.md');
    const planContent = readFileSafe(planPath);
    const planInfo = parseMarkdownHeadings(planContent);
    if (planContent) packSources.push(`evidence/${packId}/implementation-plan.md`);

    // Extract code blocks from key files
    const codeBlocks = [];
    if (changeSummaryContent) codeBlocks.push(...extractCodeBlocks(changeSummaryContent));
    if (planContent) codeBlocks.push(...extractCodeBlocks(planContent));

    // Test results
    const testResultsDir = path.join(packDir, 'test-results');
    const testResults = dirExists(testResultsDir) ? parseTestResults(testResultsDir, packId) : {};
    if (dirExists(testResultsDir)) packSources.push(`evidence/${packId}/test-results/`);

    // Screenshots
    const screenshotsDir = path.join(packDir, 'screenshots');
    const screenshotFiles = dirExists(screenshotsDir)
      ? listDirSafe(screenshotsDir).filter(f => {
          const ext = path.extname(f).toLowerCase();
          return ['.png', '.jpg', '.jpeg', '.webp', '.gif'].includes(ext);
        })
      : [];
    const screenshots = screenshotFiles.map(f => ({
      name: f,
      url: `/api/screenshots/${packId}/${encodeURIComponent(f)}`
    }));
    if (screenshotFiles.length > 0) packSources.push(`evidence/${packId}/screenshots/`);
    else packMissing.push(`evidence/${packId}/screenshots/`);

    // Review files
    const reviewFiles = listDirSafe(packDir).filter(f => f.startsWith('review-') && f.endsWith('.md'));
    const reviews = reviewFiles.map(f => {
      const content = readFileSafe(path.join(packDir, f));
      const role = f.replace('review-', '').replace('.md', '');
      packSources.push(`evidence/${packId}/${f}`);
      return extractReviewFindings(content, role);
    });

    // Fix tasks
    const fixTasksPath = path.join(packDir, 'fix-tasks.md');
    const fixTasksContent = readFileSafe(fixTasksPath);
    const fixTasks = fixTasksContent
      ? fixTasksContent.split('\n').filter(l => l.trim().startsWith('- ')).map(l => l.trim().slice(2))
      : [];

    // Determine overall status
    const allResults = verification.map(v => v.result.toUpperCase());
    const hasFail = allResults.includes('FAIL');
    const hasBlocking = reviews.some(r => r.status === 'blocking');
    const hasNonBlocking = reviews.some(r => r.status === 'non-blocking');
    let status = 'approved';
    if (hasBlocking) status = 'blocking';
    else if (hasFail || reviews.some(r => r.findings.some(f => f.severity === 'critical' || f.severity === 'high'))) status = 'non-blocking';
    else if (hasNonBlocking) status = 'non-blocking';

    const acPassed = allResults.filter(r => r === 'PASS').length;

    packs.push({
      id: packId,
      title: changeSummary.title || planInfo.title || `Issue #${packId}`,
      status,
      date: extractDate(changeSummaryContent || planContent || ''),
      acCount: verification.length,
      acPassed,
      reviewerStatus: reviews.reduce((acc, r) => { acc[r.role] = r.status; return acc; }, {}),
      verification,
      changeSummary: {
        what: extractSection(changeSummaryContent, 'What') || '',
        why: extractSection(changeSummaryContent, 'Why') || '',
        howVerified: extractSection(changeSummaryContent, 'How Verified') || ''
      },
      planInfo: {
        goal: extractSection(planContent, 'Goal Recap') || '',
        changeSurface: extractSection(planContent, 'Change Surface') || ''
      },
      testResults,
      screenshots,
      codeBlocks,
      reviews,
      fixTasks,
      findings: reviews.flatMap(r => r.findings),
      hasVerification: !!verificationContent,
      hasScreenshots: screenshotFiles.length > 0,
      hasReviews: reviewFiles.length > 0,
      hasFailures: hasFail,
      isUI: screenshotFiles.length > 0 || changeSummaryContent?.includes('screenshot') || false,
      path: packDir
    });

    sources.push(...packSources);
    missing.push(...packMissing);
  }

  return { packs, sources, missing };
}

function extractDate(content) {
  if (!content) return null;
  const dateMatch = content.match(/(\d{4}-\d{2}-\d{2})/);
  return dateMatch ? dateMatch[1] : null;
}

function extractSection(content, sectionTitle) {
  if (!content) return '';
  const regex = new RegExp(`##\\s+${sectionTitle}\\s*\\n([\\s\\S]*?)(?=\\n##|$)`, 'i');
  const m = content.match(regex);
  if (!m) return '';
  return m[1].replace(/^[-*]\s*/gm, '').trim().slice(0, 500);
}

function collectMemory() {
  const sources = [];
  const missing = [];
  const files = [];

  if (!dirExists(MEMORY_DIR)) {
    missing.push('memory/');
    return { files, sources, missing };
  }

  sources.push('memory/');

  const memoryFiles = listDirSafe(MEMORY_DIR).filter(f => f.endsWith('.md'));

  for (const file of memoryFiles) {
    const filePath = path.join(MEMORY_DIR, file);
    const content = readFileSafe(filePath);
    if (content) {
      sources.push(`memory/${file}`);
      const { title, summary } = parseMarkdownHeadings(content);
      const dateMatch = file.match(/(\d{4}-\d{2}-\d{2})/);
      files.push({
        name: file,
        title: title || file.replace('.md', ''),
        summary: summary || '',
        date: dateMatch ? dateMatch[1] : null
      });
    }
  }

  return { files, sources, missing };
}

function collectFreshness() {
  const sources = [];
  const missing = [];

  if (!fileExists(FRESHNESS_FILE)) {
    missing.push('docs/.index/freshness.json');
    return { data: { lastSync: null, files: {} }, sources, missing };
  }

  sources.push('docs/.index/freshness.json');
  try {
    const content = readFileSafe(FRESHNESS_FILE);
    const data = JSON.parse(content);
    return { data, sources, missing };
  } catch {
    return { data: { lastSync: null, files: {} }, sources, missing };
  }
}

function computeHealth(projectStatus, evidencePacks, memory, freshness) {
  const sources = [];
  const missing = [];

  let testsStatus = 'unknown';
  let ciStatus = 'unknown';
  let docsStatus = 'unknown';
  let memoryStatus = 'unknown';

  // Parse tests from evidence packs
  const allTestResults = evidencePacks.flatMap(p => Object.values(p.testResults || {}));
  if (allTestResults.length > 0) {
    const allPassed = allTestResults.every(r => r.failed === 0);
    const someFailed = allTestResults.some(r => r.failed > 0);
    testsStatus = someFailed ? 'fail' : 'pass';
  }

  // Parse CI from project status
  if (projectStatus.health) {
    const ci = projectStatus.health.ci?.toLowerCase();
    const tests = projectStatus.health.tests?.toLowerCase();
    if (ci === 'green') ciStatus = 'green';
    else if (ci === 'red') ciStatus = 'red';
    if (tests === 'green') testsStatus = 'pass';
    else if (tests === 'red') testsStatus = 'fail';
    else if (tests === 'yellow') testsStatus = 'fail';

    const docs = projectStatus.health.docs?.toLowerCase();
    if (docs === 'fresh') docsStatus = 'fresh';
    else if (docs === 'stale') docsStatus = 'stale';

    const mem = projectStatus.health.memory?.toLowerCase();
    if (mem === 'ok') memoryStatus = 'ok';
  }

  // Check freshness file
  if (freshness.lastSync) {
    const syncDate = new Date(freshness.lastSync);
    const daysSince = (Date.now() - syncDate.getTime()) / (1000 * 60 * 60 * 24);
    if (daysSince > 30) docsStatus = 'stale';
    else if (docsStatus === 'unknown') docsStatus = 'fresh';
  }

  // Evidence completeness
  const total = evidencePacks.length;
  const complete = evidencePacks.filter(p => p.hasVerification && p.testResults && Object.keys(p.testResults).length > 0).length;
  const percentage = total > 0 ? Math.round((complete / total) * 100) : 0;

  // Memory count
  const memFiles = memory.length;

  // Overall
  const hasRed = ciStatus === 'red' || testsStatus === 'fail';
  const hasYellow = docsStatus === 'stale';
  let overall = 'healthy';
  if (hasRed) overall = 'broken';
  else if (hasYellow) overall = 'degraded';

  return {
    overall,
    tests: testsStatus,
    ci: ciStatus,
    docs: docsStatus,
    evidence: { total, complete, percentage },
    memory: { files: memFiles, lastUpdated: memory.length > 0 ? memory[0].date : null }
  };
}

function computeChaosScore(projectStatus, evidencePacks, memory, freshness) {
  let score = 100;
  const issues = [];
  const bySeverity = { critical: 0, high: 0, medium: 0, low: 0 };
  const byCategory = {};

  function addIssue(severity, category, description, file, line) {
    const deduction = { critical: 10, high: 5, medium: 3, low: 1 }[severity] || 1;
    score = Math.max(0, score - deduction);
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
      if (finding.severity === 'critical') {
        addIssue('critical', 'review', `Blocking: ${finding.description}`, finding.file, finding.line);
      } else if (finding.severity === 'high') {
        addIssue('high', 'review', `High: ${finding.description}`, finding.file, finding.line);
      }
    }
  }

  // Documentation checks
  if (!projectStatus.now || projectStatus.now.length === 0) {
    addIssue('high', 'documentation', 'PROJECT_STATUS.md missing or empty', 'PROJECT_STATUS.md');
  }
  if (memory.length === 0) {
    addIssue('low', 'documentation', 'Memory directory is empty or missing', 'memory/');
  }
  if (freshness.lastSync) {
    const syncDate = new Date(freshness.lastSync);
    const daysSince = (Date.now() - syncDate.getTime()) / (1000 * 60 * 60 * 24);
    if (daysSince > 30) {
      addIssue('low', 'documentation', 'Freshness file is stale (>30 days)', 'docs/.index/freshness.json');
    }
  }

  // Testing checks
  const hasTestResults = evidencePacks.some(p => {
    const results = p.testResults || {};
    return Object.values(results).some(r => r.total > 0);
  });
  if (!hasTestResults && evidencePacks.length > 0) {
    addIssue('medium', 'testing', 'No test results found in any evidence pack', 'docs/evidence/');
  }

  // Blocked issues
  if (projectStatus.blocked) {
    for (const item of projectStatus.blocked) {
      addIssue('medium', 'blocked', `Blocked: ${item.title} — waiting for ${item.blockedOn || 'unknown'}`, 'PROJECT_STATUS.md');
    }
  }

  // CI
  if (projectStatus.health && (projectStatus.health.ci === 'red' || projectStatus.health.tests === 'red')) {
    addIssue('high', 'ci', 'CI or tests reported as red', 'PROJECT_STATUS.md');
  }

  const grade = score >= 90 ? 'A' : score >= 75 ? 'B' : score >= 60 ? 'C' : score >= 40 ? 'D' : 'F';
  return { chaosScore: score, maxScore: 100, grade, issues, bySeverity, byCategory };
}

// ─── Quick Scan (Vibe-Signs Detection) ─────────────────────────────────────────
// Issue #8: heuristic scan for common AI-generated / messy code patterns.
// Issue #9: vibe-specific signs — secrets, missing error handling, duplication,
// style drift, missing tests, and intent loss (code vs. its own doc comment).

// Verb pairs that contradict each other. A doc comment leading with one verb
// while the function is named the other is a strong sign the code drifted away
// from the description someone (or some model) wrote for it.
const ANTONYM_VERBS = [
  ['add', 'subtract'], ['add', 'remove'], ['add', 'delete'],
  ['get', 'set'], ['read', 'write'], ['open', 'close'],
  ['enable', 'disable'], ['start', 'stop'], ['create', 'destroy'],
  ['create', 'delete'], ['increment', 'decrement'], ['show', 'hide'],
  ['lock', 'unlock'], ['encrypt', 'decrypt'], ['push', 'pop'],
  ['connect', 'disconnect'], ['serialize', 'deserialize'],
  ['encode', 'decode'], ['compress', 'decompress'], ['attach', 'detach'],
  ['mount', 'unmount'], ['register', 'unregister'], ['insert', 'remove'],
  ['multiply', 'divide'], ['expand', 'collapse'], ['import', 'export'],
  ['load', 'save'], ['grant', 'revoke'], ['subscribe', 'unsubscribe'],
];

const ANTONYM_MAP = (() => {
  const m = new Map();
  for (const [a, b] of ANTONYM_VERBS) {
    if (!m.has(a)) m.set(a, new Set());
    if (!m.has(b)) m.set(b, new Set());
    m.get(a).add(b);
    m.get(b).add(a);
  }
  return m;
})();

// Function signatures across the languages in SOURCE_EXTS. Java/C#-style
// `Type name(...)` methods are deliberately excluded — too ambiguous to match
// without false positives on calls and casts.
const FN_SIGNATURE_PATTERNS = [
  /^(?:export\s+)?(?:default\s+)?(?:async\s+)?function\s*\*?\s*([A-Za-z_$][\w$]*)\s*\(([^)]*)\)/,
  /^(?:export\s+)?(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*(?::[^=]+)?=\s*(?:async\s*)?\(([^)]*)\)\s*=>/,
  /^(?:async\s+)?def\s+([A-Za-z_]\w*)\s*\(([^)]*)\)/,
  /^func\s+(?:\([^)]*\)\s*)?([A-Za-z_]\w*)\s*\(([^)]*)\)/,
  /^(?:pub\s+)?(?:async\s+)?fn\s+([A-Za-z_]\w*)\s*(?:<[^>]*>)?\s*\(([^)]*)\)/,
];

// "Adds" → "add", "Fetches" → "fetch", "Copies" → "copy"
function normalizeVerb(word) {
  const w = String(word).toLowerCase().replace(/[^a-z]/g, '');
  if (!w) return '';
  if (w.endsWith('ies') && w.length > 4) return w.slice(0, -3) + 'y';
  if (/(?:sh|ch|ss|x|z)es$/.test(w)) return w.slice(0, -2);
  if (w.endsWith('s') && !w.endsWith('ss')) return w.slice(0, -1);
  return w;
}

// getUserName → "get", save_config → "save"
function leadingNameVerb(name) {
  const parts = String(name)
    .replace(/[_-]+/g, ' ')
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
    .trim()
    .split(/\s+/);
  return normalizeVerb(parts[0] || '');
}

// Returns an array of parameter names, or null when the signature is too
// complex to match names reliably (destructuring, generics, nested calls).
function parseParamNames(raw) {
  const s = String(raw).trim();
  if (!s) return [];
  if (/[{}[\]<>(]/.test(s)) return null;
  const names = [];
  for (const part of s.split(',')) {
    const ident = part.trim().replace(/^[.*&\s]+/, '').match(/^([A-Za-z_$][\w$]*)/);
    if (!ident) continue;
    const name = ident[1];
    if (name === 'self' || name === 'this') continue;
    names.push(name);
  }
  return names;
}

// Walks backwards from a signature line to collect the doc comment attached to
// it — a /** */ block, or a run of consecutive // or # lines.
function collectDocComment(lines, sigIndex) {
  let j = sigIndex - 1;
  let skipped = 0;
  while (j >= 0 && skipped < 3 && (lines[j].trim() === '' || /^\s*@\w+/.test(lines[j]))) {
    j--;
    skipped++;
  }
  if (j < 0) return '';
  const collected = [];
  if (/\*\/\s*$/.test(lines[j])) {
    while (j >= 0) {
      collected.unshift(lines[j]);
      if (/\/\*/.test(lines[j])) break;
      j--;
    }
    return j < 0 ? '' : collected.join('\n');
  }
  while (j >= 0 && /^\s*(?:\/\/|#)/.test(lines[j])) {
    collected.unshift(lines[j]);
    j--;
  }
  return collected.join('\n');
}

// Body text between the signature's opening brace and its match, or null when
// braces don't balance within the window (or the language has none).
function collectFunctionBody(lines, sigIndex) {
  let depth = 0;
  let started = false;
  const collected = [];
  const limit = Math.min(sigIndex + 150, lines.length);
  for (let i = sigIndex; i < limit; i++) {
    for (const ch of lines[i]) {
      if (ch === '{') { depth++; started = true; }
      else if (ch === '}') depth--;
    }
    collected.push(lines[i]);
    if (started && depth <= 0) return collected.join('\n');
  }
  return null;
}

// Yields { doc, name, params, body, line } for every documented function.
function extractDocumentedFunctions(content) {
  const lines = content.split('\n');
  const found = [];
  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (!trimmed) continue;
    let match = null;
    for (const pat of FN_SIGNATURE_PATTERNS) {
      match = trimmed.match(pat);
      if (match) break;
    }
    if (!match) continue;
    const doc = collectDocComment(lines, i);
    if (!doc) continue;
    found.push({
      doc,
      name: match[1],
      params: parseParamNames(match[2] || ''),
      body: collectFunctionBody(lines, i),
      line: i + 1,
    });
  }
  return found;
}

// Compares a function against its own doc comment. Returns the first
// contradiction found, or null.
function findIntentMismatch(fn) {
  const docText = fn.doc.replace(/^\s*(?:\/\*+|\*+\/|\*|\/\/|#)\s?/gm, ' ');
  const prose = docText.replace(/@\w+[^\n]*/g, ' ').trim();
  if (!prose && !/@\w/.test(docText)) return null;

  // a) The doc leads with the opposite of the function's own verb.
  const nameVerb = leadingNameVerb(fn.name);
  const firstWord = (prose.match(/[A-Za-z]+/) || [''])[0];
  const docVerb = normalizeVerb(firstWord);
  const opposites = ANTONYM_MAP.get(docVerb);
  if (opposites && opposites.has(nameVerb)) {
    // If the doc also mentions the function's own verb, it is describing both
    // sides of the operation rather than contradicting itself.
    if (!new RegExp(`\\b${nameVerb}`, 'i').test(prose)) {
      return {
        severity: 'medium',
        description: `Doc says "${firstWord}..." but function is named ${fn.name}()`,
      };
    }
  }

  // b) A documented @param that no longer exists in the signature.
  if (fn.params !== null) {
    const documented = [];
    const paramRe = /@param\s+(?:\{[^}]*\}\s*)?\[?([A-Za-z_$][\w$.]*)/g;
    let m;
    while ((m = paramRe.exec(docText)) !== null) {
      const name = m[1].split('.')[0];
      // Malformed docs like `@param {string} The string to inspect.` capture a
      // prose word, not a name. Identifiers conventionally start lowercase, _,
      // or $ — anything else is a doc typo, not intent drift.
      if (!/^[a-z_$]/.test(name)) continue;
      documented.push(name);
    }
    if (documented.length > 0) {
      const actual = new Set(fn.params);
      const stale = documented.filter(p => !actual.has(p));
      if (stale.length > 0) {
        return {
          severity: 'low',
          description: `@param ${stale[0]} documented but missing from ${fn.name}() signature`,
        };
      }
    }
  }

  // c) A documented return value the function never produces.
  const returnsSomething = /@returns?\b\s*(?:\{\s*)?(?!\s*(?:void|None|undefined|nothing)\b)\S/.test(docText);
  if (returnsSomething && fn.body !== null) {
    if (!/\breturn\s+[^;\s}]/.test(fn.body) && !/\byield\b/.test(fn.body)) {
      return {
        severity: 'low',
        description: `@returns documented but ${fn.name}() never returns a value`,
      };
    }
  }

  return null;
}

// Is the secret-shaped value on this line obviously NOT a real secret?
//
// This replaces a filename-based exemption that skipped config files wholesale
// (see the call site). Config files do carry a lot of secret-shaped scaffolding,
// but so does every other file, and the distinguishing property is the value --
// so it is judged here, uniformly, instead of by path.
//
// Deliberately narrow: it only clears values that are structurally incapable of
// being a credential, or that are self-evidently a stand-in. When unsure it
// returns false and the finding is reported -- a false positive on a placeholder
// costs a glance, a false negative on a live key costs the key.
function isPlaceholderSecret(line) {
  // Documentation, not code. Measured on 282 MB of third-party JS/TS: doc-comment
  // examples were the single largest false-positive class (~40 of 46 suppressed
  // hits), overwhelmingly `@types/node`'s `* const password = 'Password used to
  // generate key';` and `@noble/curves`' worked examples. A key inside a `*`
  // continuation line or a `//` comment is illustrating an API, not leaking a
  // credential. This mirrors the comment-stripping the placeholder-name detector
  // already does at its own call site.
  if (/^\s*(\*|\/\/|#\s|--\s)/.test(line)) return true;

  // Extract the quoted value the secret pattern matched, if any.
  const m = line.match(/[=:]\s*['"]([^'"]*)['"]/);
  const value = m ? m[1] : '';

  // An empty or whitespace-only literal cannot be a credential.
  if (m && !value.trim()) return true;

  // Indirection, not a literal: env vars, config lookups, template holes,
  // interpolation. `apiKey: process.env.API_KEY` is the *correct* pattern and
  // must never be flagged, or the detector punishes the fix it wants.
  if (/(process\.env|os\.environ|getenv|ENV\[|secrets?\.get|config\.get|vault|\$\{|\{\{|%s|%\(|<%=)/i.test(line)) return true;

  if (value) {
    // Self-labelled stand-ins.
    if (/^(x{3,}|\*{3,}|\.{3,}|-{3,}|_{3,})$/i.test(value)) return true;
    if (/(your[_-]?|my[_-]?|some[_-]?|the[_-]?)?(api[_-]?key|secret|token|password|passwd|value)[_-]?(here|goes[_-]?here)?$/i.test(value)
        && /^(your|my|some|the|placeholder|dummy|example|sample|changeme|change[_-]?me|replace[_-]?me|todo|fixme|insert|xxx|test|fake|foo|bar)/i.test(value)) return true;
    if (/^(changeme|change[_-]?me|replace[_-]?me|placeholder|dummy|example|sample|todo|fixme|none|null|nil|undefined|empty|n\/a|redacted|hidden|omitted)$/i.test(value)) return true;
    // Documentation-style example keys. AWS's own docs use EXAMPLE as the marker.
    if (/(EXAMPLE|SAMPLE|DUMMY|FAKE|PLACEHOLDER|REDACTED|XXXXX)/.test(value)) return true;
    // Too short to be a credential. Real keys have entropy and length; the
    // patterns already require 8+ chars for most cases, this catches the rest.
    if (value.length < 8) return true;
    // No entropy at all -- a single repeated character.
    if (/^(.)\1*$/.test(value)) return true;
  }

  return false;
}

function detectVibeSigns() {
  const issues = [];
  const byCategory = {};
  const bySeverity = { critical: 0, high: 0, medium: 0, low: 0 };

  let score = 100;
  function addIssue(severity, category, description, file, line) {
    const deduction = { critical: 10, high: 5, medium: 3, low: 1 }[severity] || 1;
    score = Math.max(0, score - deduction);
    issues.push({ severity, category, description, file: file || '', line: line || null });
    bySeverity[severity]++;
    byCategory[category] = (byCategory[category] || 0) + 1;
  }

  // Collect all source files in the project
  const sourceDirs = SOURCE_DIRS.filter(d => dirExists(path.join(PROJECT_ROOT, d)));
  const allFiles = [];
  for (const dir of sourceDirs) {
    const fullDir = path.join(PROJECT_ROOT, dir);
    const files = listAllFiles(fullDir).filter(f => {
      const ext = path.extname(f).toLowerCase();
      // skip node_modules, .git, dist, build, __pycache__
      const parts = path.relative(fullDir, f).split(path.sep);
      if (parts[0] === 'node_modules' || parts[0] === '.git' || parts[0] === '__pycache__') return false;
      if (ext === '.map' || ext === '.d.ts') return false;
      return SOURCE_EXTS.includes(ext);
    });
    allFiles.push(...files);
  }

  if (allFiles.length === 0) {
    // No source files found — perfect score, no issues
    return { chaosScore: 100, maxScore: 100, grade: 'A', issues: [], bySeverity, byCategory, filesScanned: 0 };
  }

  // Track seen content for duplicate detection
  const blockMap = new Map(); // signature → [{ file, line }]

  for (const filePath of allFiles) {
    const relPath = path.relative(PROJECT_ROOT, filePath);
    const content = readFileSafe(filePath);
    if (!content) continue;
    const lines = content.split('\n');
    const ext = path.extname(filePath).toLowerCase();

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineNum = i + 1;

      // 1. Hardcoded secrets (HIGH)
      //
      // This used to be skipped entirely for config files (`src/config*`,
      // `*.config.ts`, ...). That exemption was backwards: a config file is the
      // single most likely place for a real key to be pasted, so the one file a
      // reviewer most wants scanned was the one file never scanned. It shipped
      // in e9f9c3a together with a test whose fixture planted a key in
      // `src/config.ts` -- detector and test contradicted each other from birth,
      // and the test only "passed" locally because bats 1.13 swallows a failing
      // bare `[[ ]]` mid-body. CI (bats 1.10) had been telling the truth.
      //
      // The exemption was aiming at a real problem -- config files carry
      // `apiKey: process.env.KEY` and `password: "changeme"` scaffolding -- but
      // that is a property of the *value*, not of the filename. So judge the
      // value instead, everywhere.
      const secretPatterns = [
        /\b(api[_-]?key|apikey)\s*[=:]\s*['"][^'"]{8,}['"]/i,
        /\b(api[_-]?key|apikey)\s*[=:]\s*['"][^'"]+['"]\s*[,)]/i,
        /\b(token|secret|password|passwd|private[_-]?key)\s*[=:]\s*['"][^'"]{8,}['"]/i,
        /\b(aws_access_key_id|aws_secret_access_key)\s*[=:]\s*['"][^'"]+/i,
        /\b(SK-[a-zA-Z0-9]{20,})\b/,
        /\b(ghp_[a-zA-Z0-9]{36})\b/,
        /\b(AIza[a-zA-Z0-9_-]{35})\b/,
        /\b(eyJ[a-zA-Z0-9_-]{20,}\.eyJ[a-zA-Z0-9_-]{20,})/,
      ];
      for (const pat of secretPatterns) {
        if (pat.test(line) && !isPlaceholderSecret(line)) {
          addIssue('high', 'security', `Potential hardcoded secret`, relPath, lineNum);
          break;
        }
      }

      // 2. Missing error handling — try without catch (MEDIUM)
      const trimmed = line.trim();
      if (/^try\s*\{/.test(trimmed) && i + 1 < lines.length) {
        let hasCatch = false;
        for (let j = i + 1; j < Math.min(i + 30, lines.length); j++) {
          if (/^\}\s*catch\b/.test(lines[j].trim())) { hasCatch = true; break; }
          if (/^\}/.test(lines[j].trim()) && j > i + 1) break; // brace closed without catch
        }
        if (!hasCatch) {
          addIssue('medium', 'reliability', 'try block without catch handler', relPath, lineNum);
        }
      }

      // 3. Placeholder names (LOW)
      const placeholderPattern = /\b(foo|bar|baz|temp|xxx|placeholder|dummy|asdf|qwerty)\b/;
      // Only flag if it's a function name, class name, or variable declaration (not comments)
      const codePart = line.replace(/\/\/.*$/, '').replace(/\/\*[\s\S]*?\*\//, '').trim();
      if (placeholderPattern.test(codePart)) {
        // Skip if it's clearly a valid use (e.g., "foo === bar" in a test)
        const fnMatch = line.match(/function\s+(foo|bar|baz|temp|xxx|placeholder)\b/i);
        const clsMatch = line.match(/class\s+(foo|bar|baz|temp|xxx|placeholder)\b/i);
        const constMatch = line.match(/(const|let|var)\s+(foo|bar|baz|temp|xxx|placeholder)\b/i);
        const paramMatch = line.match(/\(\s*(foo|bar|baz|temp|xxx|placeholder)\s*[,)]/);
        if (fnMatch || clsMatch || constMatch || paramMatch) {
          addIssue('low', 'code-hygiene', 'Placeholder name used in code', relPath, lineNum);
        }
      }

      // 4. Commented-out code (LOW)
      if (/^[\s]*\/{3,}/.test(line) || /^[\s]*\/\*[\s]*[\*]/.test(line)) {
        // Single-line block comments
        if (i + 1 < lines.length && (lines[i + 1].trim().startsWith('//') || lines[i + 1].trim().startsWith('*'))) {
          // Look ahead for 3+ consecutive comment lines
          let count = 1;
          for (let j = i + 1; j < Math.min(i + 10, lines.length); j++) {
            if (lines[j].trim().startsWith('//') || lines[j].trim().startsWith('*') || lines[j].trim().startsWith('/*')) {
              count++;
            } else break;
          }
          if (count >= 3) {
            addIssue('low', 'code-hygiene', `${count} lines of commented-out code`, relPath, lineNum);
          }
        }
      }
      // Also check multi-line /* */ blocks
      if (/\/\*/.test(line) && !/\*\//.test(line) && !line.trim().startsWith('/**')) {
        // Start of a multi-line comment block (not docblock)
        let commentLines = 1;
        let j = i + 1;
        while (j < lines.length && !lines[j].includes('*/')) {
          if (lines[j].trim().length > 0) commentLines++;
          j++;
        }
        if (commentLines >= 3) {
          addIssue('low', 'code-hygiene', `${commentLines} lines of commented-out block`, relPath, lineNum);
        }
      }

      // 5. TODO markers without issue links (LOW)
      if (/\/\/\s*(TODO|FIXME|HACK|XXX)\b/.test(line) && !/#\d+/.test(line)) {
        addIssue('low', 'code-hygiene', 'TODO/FIXME without issue link', relPath, lineNum);
      }

      // 6. Duplicate blocks (MEDIUM) — track 3-line blocks
      if (i + 2 < lines.length) {
        const block = [lines[i].trim(), lines[i + 1].trim(), lines[i + 2].trim()];
        // Skip blocks that are all empty or comments
        const nonEmpty = block.filter(l => l.length > 0 && !l.startsWith('//') && !l.startsWith('*') && !l.startsWith('/*')).length;
        if (nonEmpty >= 2) {
          const sig = block.join('|||');
          if (!blockMap.has(sig)) blockMap.set(sig, []);
          blockMap.get(sig).push({ file: relPath, line: lineNum });
        }
      }
    }
  }

  // Report duplicates
  for (const [sig, locations] of blockMap) {
    if (locations.length >= 2) {
      const files = [...new Set(locations.map(l => l.file))];
      const firstLine = locations[0].line;
      addIssue('medium', 'duplication', `Duplicate code block (${locations.length} copies in ${files.length} file(s))`, files[0], firstLine);
    }
  }

  // 7. Missing tests (MEDIUM)
  const testDirExists = dirExists(path.join(PROJECT_ROOT, 'test')) ||
                        dirExists(path.join(PROJECT_ROOT, 'tests')) ||
                        dirExists(path.join(PROJECT_ROOT, '__tests__')) ||
                        dirExists(path.join(PROJECT_ROOT, 'spec'));
  const sourceFiles = allFiles;
  let untested = 0;
  for (const sf of sourceFiles) {
    const base = path.basename(sf, path.extname(sf));
    const dir = path.dirname(sf);
    const hasTest = listAllFiles(dir).some(f => {
      const fn = path.basename(f);
      return fn === `${base}.test${path.extname(f)}` ||
             fn === `${base}.spec${path.extname(f)}` ||
             fn === `${base}.test.js` ||
             fn === `${base}.test.ts` ||
             fn === `${base}.spec.js` ||
             fn === `${base}.spec.ts`;
    });
    if (!hasTest) untested++;
  }
  if (untested > 0 && sourceFiles.length > 0) {
    addIssue('medium', 'testing', `${untested} source file${untested !== 1 ? 's' : ''} without corresponding test file(s)`, null, null);
  }

  // 8. Style drift — mixed indentation within a file (MEDIUM)
  for (const filePath of allFiles) {
    const relPath = path.relative(PROJECT_ROOT, filePath);
    const content = readFileSafe(filePath);
    if (!content || content.split('\n').length < 5) continue;
    const lines = content.split('\n');
    let hasTab = false, hasSpace = false;
    for (const ln of lines) {
      if (ln.length === 0) continue;
      const leading = ln.match(/^[\s]+/);
      if (leading && leading[0].length > 0) {
        if (/\t/.test(leading[0])) hasTab = true;
        if (/[ ]{2,}/.test(leading[0])) hasSpace = true;
      }
      if (hasTab && hasSpace) break;
    }
    if (hasTab && hasSpace) {
      addIssue('medium', 'style-drift', 'Mixed tabs and spaces for indentation', relPath, 1);
    }
  }

  // 9. Dead code after early return (LOW)
  for (const filePath of allFiles) {
    const relPath = path.relative(PROJECT_ROOT, filePath);
    const content = readFileSafe(filePath);
    if (!content) continue;
    const lines = content.split('\n');
    // Find returns/throws and check for significant code after
    for (let i = 0; i < lines.length; i++) {
      const trimmed = lines[i].trim();
      if (/^(return|throw|exit\(|process\.exit)\b/.test(trimmed)) {
        // Look ahead: if there are 5+ non-empty, non-comment lines after, flag it
        let codeAfter = 0;
        for (let j = i + 1; j < Math.min(i + 20, lines.length); j++) {
          const t = lines[j].trim();
          if (t.length === 0 || t.startsWith('//') || t.startsWith('*') || t.startsWith('/*') || t.startsWith('}')) continue;
          codeAfter++;
        }
        if (codeAfter >= 5) {
          addIssue('low', 'dead-code', `${codeAfter} lines of unreachable code after return/throw`, relPath, i + 1);
          break; // one flag per file is enough
        }
      }
    }
  }

  // 10. Intent loss — code contradicts its own doc comment (MEDIUM/LOW)
  for (const filePath of allFiles) {
    const relPath = path.relative(PROJECT_ROOT, filePath);
    const content = readFileSafe(filePath);
    if (!content) continue;
    let flagged = 0;
    for (const fn of extractDocumentedFunctions(content)) {
      const mismatch = findIntentMismatch(fn);
      if (!mismatch) continue;
      addIssue(mismatch.severity, 'intent-mismatch', mismatch.description, relPath, fn.line);
      if (++flagged >= 3) break; // cap per file so one stale file can't flood the report
    }
  }

  const grade = score >= 90 ? 'A' : score >= 75 ? 'B' : score >= 60 ? 'C' : score >= 40 ? 'D' : 'F';
  return { chaosScore: score, maxScore: 100, grade, issues: issues.slice(0, 20), bySeverity, byCategory, filesScanned: allFiles.length };
}

// ─── Request Handlers ─────────────────────────────────────────────────────────

function handleHealth(req, res) {
  const sources = [];
  const missing = [];

  const { data: projectStatus, sources: psSources, missing: psMissing } = collectProjectStatus();
  sources.push(...psSources);
  missing.push(...psMissing);

  const { packs: evidencePacks, sources: evSources, missing: evMissing } = collectEvidencePacks();
  sources.push(...evSources);
  missing.push(...evMissing);

  const { files: memory, sources: memSources, missing: memMissing } = collectMemory();
  sources.push(...memSources);
  missing.push(...memMissing);

  const { data: freshness, sources: frSources, missing: frMissing } = collectFreshness();
  sources.push(...frSources);
  missing.push(...frMissing);

  const health = computeHealth(projectStatus, evidencePacks, memory, freshness);
  jsonResponse(res, 200, { ...health, _meta: meta(sources, missing) });
}

function handleProjectStatus(req, res) {
  const { data: projectStatus, sources, missing } = collectProjectStatus();
  jsonResponse(res, 200, { ...projectStatus, _meta: meta(sources, missing) });
}

function handleEvidence(req, res) {
  const { packs, sources, missing } = collectEvidencePacks();
  const summaries = packs.map(p => ({
    id: p.id,
    title: p.title,
    status: p.status,
    date: p.date,
    acCount: p.acCount,
    acPassed: p.acPassed,
    reviewerStatus: p.reviewerStatus
  }));
  jsonResponse(res, 200, { packs: summaries, _meta: meta(sources, missing) });
}

function handleEvidenceDetail(req, res, packId) {
  const { packs, sources, missing } = collectEvidencePacks();
  const pack = packs.find(p => p.id === packId);

  if (!pack) {
    return jsonResponse(res, 404, { error: `Evidence pack #${packId} not found`, _meta: meta(sources, missing) });
  }

  jsonResponse(res, 200, { ...pack, _meta: meta(sources, missing) });
}

function handleMemory(req, res) {
  const { files, sources, missing } = collectMemory();
  jsonResponse(res, 200, { files, _meta: meta(sources, missing) });
}

function handleKanban(req, res) {
  const { data: projectStatus, sources, missing } = collectProjectStatus();

  const kanban = {
    now: (projectStatus.now || []).map(item => ({ id: '', ...item })),
    backlog: (projectStatus.backlog || []).map(item => ({ id: '', ...item })),
    blocked: (projectStatus.blocked || []).map(item => ({ id: '', ...item })),
    recentlyMerged: (projectStatus.recentlyMerged || []).map(item => ({ id: '', ...item }))
  };

  // Add PR numbers from reviewer threads for recentlyMerged items
  if (projectStatus.reviewerThreads) {
    for (const thread of projectStatus.reviewerThreads) {
      const idx = kanban.recentlyMerged.findIndex(item => item.pr === thread.pr);
      if (idx >= 0) {
        kanban.recentlyMerged[idx] = { ...kanban.recentlyMerged[idx], ...thread };
      }
    }
  }

  jsonResponse(res, 200, { ...kanban, _meta: meta(sources, missing) });
}

function handleTakeoverAudit(req, res) {
  const sources = [];
  const missing = [];

  const { data: projectStatus, sources: psSources, missing: psMissing } = collectProjectStatus();
  sources.push(...psSources);
  missing.push(...psMissing);

  const { packs: evidencePacks, sources: evSources, missing: evMissing } = collectEvidencePacks();
  sources.push(...evSources);
  missing.push(...evMissing);

  const { files: memory, sources: memSources, missing: memMissing } = collectMemory();
  sources.push(...memSources);
  missing.push(...memMissing);

  const { data: freshness, sources: frSources, missing: frMissing } = collectFreshness();
  sources.push(...frSources);
  missing.push(...frMissing);

  const audit = computeChaosScore(projectStatus, evidencePacks, memory, freshness);
  jsonResponse(res, 200, { ...audit, _meta: meta(sources, missing) });
}

function handleQuickScan(req, res) {
  const result = detectVibeSigns();
  jsonResponse(res, 200, { ...result, _meta: { projectRoot: PROJECT_ROOT, scanTime: new Date().toISOString() } });
}

function handleScreenshot(req, res, packId, fileName) {
  const screenshotPath = path.join(EVIDENCE_DIR, packId, 'screenshots', decodeURIComponent(fileName));
  const ext = path.extname(screenshotPath).toLowerCase();
  const mimeTypes = {
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.webp': 'image/webp',
    '.gif': 'image/gif'
  };
  const contentType = mimeTypes[ext] || 'application/octet-stream';
  imageResponse(res, 200, screenshotPath, contentType);
}

function handleDashboard(req, res) {
  htmlResponse(res, 200, dashboardHtml);
}

// ─── Load Dashboard HTML ──────────────────────────────────────────────────────

function loadDashboardHtml() {
  const htmlPath = path.join(DASHBOARD_DIR, 'dashboard.html');
  try {
    dashboardHtml = fs.readFileSync(htmlPath, 'utf-8');
    console.error(`[dashboard] Loaded dashboard.html from ${htmlPath}`);
  } catch {
    console.error(`[dashboard] WARNING: dashboard.html not found at ${htmlPath}`);
    console.error(`[dashboard] Run the bootstrap workflow to create it.`);
    dashboardHtml = `<!DOCTYPE html>
<html lang="en">
<head><title>Dashboard</title></head>
<body style="background:#0a0e17;color:#e2e8f0;font-family:system-ui;padding:2rem">
  <h1>Dashboard not found</h1>
  <p>Run the bootstrap workflow to create the dashboard files.</p>
  <p style="color:#94a3b8">Expected: .dashboard/dashboard.html</p>
</body>
</html>`;
  }
}

// ─── Server ───────────────────────────────────────────────────────────────────

function createServer() {
  const server = http.createServer((req, res) => {
    const u = new URL(req.url, 'http://localhost');
    const pathname = u.pathname;
    const query = u.searchParams;

    // CORS preflight
    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      });
      res.end();
      return;
    }

    // API routes
    if (pathname === '/api/health' && req.method === 'GET') {
      return handleHealth(req, res);
    }
    if (pathname === '/api/project-status' && req.method === 'GET') {
      return handleProjectStatus(req, res);
    }
    if (pathname === '/api/evidence' && req.method === 'GET') {
      return handleEvidence(req, res);
    }
    if (pathname === '/api/memory' && req.method === 'GET') {
      return handleMemory(req, res);
    }
    if (pathname === '/api/kanban' && req.method === 'GET') {
      return handleKanban(req, res);
    }
    if (pathname === '/api/takeover-audit' && req.method === 'GET') {
      return handleTakeoverAudit(req, res);
    }
    if (pathname === '/api/quick-scan' && req.method === 'GET') {
      return handleQuickScan(req, res);
    }

    // Screenshot: /api/screenshots/:packId/:fileName
    const screenshotMatch = pathname.match(/^\/api\/screenshots\/([^/]+)\/(.+)$/);
    if (screenshotMatch && req.method === 'GET') {
      return handleScreenshot(req, res, screenshotMatch[1], screenshotMatch[2]);
    }

    // Evidence detail: /api/evidence/:id
    const evidenceMatch = pathname.match(/^\/api\/evidence\/([^/]+)$/);
    if (evidenceMatch && req.method === 'GET') {
      return handleEvidenceDetail(req, res, evidenceMatch[1]);
    }

    // Root → dashboard HTML
    if (pathname === '/' && req.method === 'GET') {
      return handleDashboard(req, res);
    }

    // 404
    jsonResponse(res, 404, { error: `Not found: ${pathname}`, _meta: meta([], [pathname]) });
  });

  return server;
}

// ─── Entry Point ──────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
if (args.includes('--static-only')) {
  // Static-only mode: just serve the HTML file
  const staticDir = DASHBOARD_DIR;
  const staticServer = http.createServer((req, res) => {
    const u = new URL(req.url, 'http://localhost');
    let filePath = path.join(staticDir, u.pathname === '/' ? 'dashboard.html' : u.pathname);

    // Security: prevent directory traversal
    if (!filePath.startsWith(staticDir)) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }

    try {
      const data = fs.readFileSync(filePath);
      const ext = path.extname(filePath);
      const mimeTypes = {
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.svg': 'image/svg+xml'
      };
      res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
      res.end(data);
    } catch {
      res.writeHead(404);
      res.end('Not found');
    }
  });

  staticServer.listen(PORT, () => {
    console.error(`[dashboard] Static server running on http://localhost:${PORT}`);
  });
} else {
  loadDashboardHtml();

  const server = createServer();
  server.listen(PORT, () => {
    console.error(`[dashboard] Server running on http://localhost:${PORT}`);
    console.error(`[dashboard] Project root: ${PROJECT_ROOT}`);
    console.error(`[dashboard] Dashboard: http://localhost:${PORT}/`);
    console.error(`[dashboard] API: http://localhost:${PORT}/api/health`);
  });

  // Graceful shutdown
  process.on('SIGINT', () => {
    console.error('\n[dashboard] Shutting down...');
    server.close(() => process.exit(0));
  });
}
