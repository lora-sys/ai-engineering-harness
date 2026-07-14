# AI Engineering Harness

> 一个由 AI Agent 组成的软件工程组织,负责把你脑子里到生产环境的每一行代码变成可验证、可审查、可追溯的工程交付。
>
> A software-engineering organization of AI agents that turns every idea into verifiable, reviewable, shippable code — Issue → Worktree → Plan → Implement → Adversarial Review → Evidence → Merge → Memory.

<p align="left">
  <a href="#-one-line-install"><img alt="install" src="https://img.shields.io/badge/install-npx%20skills%20add%20lora--sys%2Fai--engineering--harness-111"></a>
  <a href="./LICENSE"><img alt="license" src="https://img.shields.io/badge/license-MIT-blue"></a>
  <a href="https://github.com/lora-sys/ai-engineering-harness"><img alt="stars" src="https://img.shields.io/badge/stars-%E2%AD%90%EF%B8%8F-yellow"></a>
</p>

![Architecture · AI Engineering Harness](./assets/architecture.svg)

*Coordinator reads docs, owns the kanban, and spawns 18 Agent personas across 9 closed-loop workflows. Every cycle is evidence-gated: code reaches `main` only when CI is green, ≥2 cold-start reviewers approve, and the Evidence pack is complete. Memory is promoted every cycle so the project gets smarter without losing it to chat history.*


**Social preview**:  [assets/social-preview.png](./assets/social-preview.png) (1200×630, for Twitter / GitHub social cards).

### 海报 · Poster

![AI Engineering Harness poster](assets/poster-harness.png)

> 让每一行代码,都有证据。18 AGENTS · 9 WORKFLOWS · ONE CLOSED LOOP. ISSUE → WORKTREE → PLAN → BUILD → REVIEW → EVIDENCE → MERGE → MEMORY.

---

---

## 中文 (Chinese)

> **English version**: [README_EN.md](README_EN.md) · **中文版本**: 你正在看这个

## 中文

### 这是什么

**3 个 skill 的家族**,可以单独或一起装:

- **`$ai-engineering-harness`** (本 skill) — 工程协调(Issue → PR → Merge → Memory)
- **`$build-agent-app`** — 设计 agent app(Agent + Harness 合约),交给本 skill 实现
- **`$frontend-creative`** — Awwwards 级创意 web UI 生成

`ai-engineering-harness` 不是单条 Prompt,而是一整套**软件工程组织操作系统**。你给一个想法、一份 PRD,或者一个需要接手的老项目,Harness 会代你组建一个由 18 类 Agent 组成的工程团队:

| Agent 角色 | 职责 |
| --- | --- |
| Coordinator(协调员) | 读文档、维护 Project Status、分派任务,自己不写业务代码 |
| Explore / Plan | 探索代码库 / 编写可验收的实施计划 |
| Frontend / Backend / Database | 按 Issue + 计划在独立 Worktree 里实现 |
| QA | 跑测试、收集证据(截图、Playwright、API trace、DB 数据) |
| Bug Hunter / Behavior / Architecture Reviewer | **冷启动对抗式审查**,默认"实现一定有 Bug",只读 PR diff 和证据 |
| Security / UI Reviewer | 条件触发(权限/支付/隐私 → Security;UI → UI) |
| Conflict Resolver / Release / Review Aggregator | 冲突仲裁、发布前体检、审查汇总 |
| Context Assembly / Memory Curator | 按 L0–L3 控制上下文,沉淀阶段经验 |

每一次特性、每一次重构、每一次修复都走同一条闭环:

```
Idea → PRD → Issue → Agent 认领 → Worktree → 实施计划
     → 实现 → 自测 → Draft PR → CI → 对抗式审查 → 修 → 再审
     → 证据闸门 → 必要时人工审批 → 合并 → 阶段总结 → 记忆沉淀 → 下一轮
```

代码只有在 **CI Pass + 至少 2 名冷启动审查员 Approved + 证据完整 + 必要时人工批准** 时才进入 `main`。没有"看起来跑通了"这种状态——只有"可验证地跑通了"。

### 一行安装(全局生效到所有 CLI Agent)

```bash
npx -y skills add lora-sys/ai-engineering-harness -g --all
```

- `-g`:全局安装(写入用户级 skill 目录,而非当前项目)
- `--all`:把仓库里的所有 skill 安装到 **所有** 受支持的 CLI 编码 Agent

完成后,这套 Skill 会被放到 `~/.claude/skills/ai-engineering-harness/`、`~/.cursor/skills/ai-engineering-harness/`、`~/.gemini/skills/ai-engineering-harness/`、`~/.qwen/skills/ai-engineering-harness/`、`~/.grok/skills/ai-engineering-harness/`、`~/.codex/skills/ai-engineering-harness/`(默认直接 cp,可写就装)等 38 个 CLI Agent 的全局 Skill 目录。



> ⚠️ **`--all` 到底装什么**
>
> `npx skills add lora-sys/ai-engineering-harness -g --all` 会把**本仓库所有 Skill** 一次性装到 **所有受支持的 Agent** — 全局生效。
>
> 当前仓库里只有 **1 个 Skill**(`ai-engineering-harness`),所以 `--all` 等价于只装它,**安全**。
>
> 以后如果在这个仓库里加入姊妹 Skill,`--all` 会一并装,不再二次确认。这是 Vercel `skills` CLI 的设计意图(一行命令拿整套工具集),但也意味着:装第三方 fork 出来的多 skill 仓库时,**应该先预览再装**。下面三条命令用来限制范围:
>
> ```bash
> # 装之前先看看里面有什么
> npx -y skills add lora-sys/ai-engineering-harness --list
>
> # 只装这一个 skill
> npx -y skills add lora-sys/ai-engineering-harness -g -s ai-engineering-harness
>
> # 只装到指定 agent
> npx -y skills add lora-sys/ai-engineering-harness -g -a claude-code codex grok
>
> # 同时限定:一个 skill 一个 agent
> npx -y skills add lora-sys/ai-engineering-harness -g -s ai-engineering-harness -a claude-code
> ```
>
> 索引器使用的完整元数据见仓库根目录的 [`meta.json`](./meta.json)。

兼容性矩阵覆盖:Claude Code、Codex、Grok、Cursor、Gemini、Qwen、Cline、Hermes-Agent、Aider Desk、Amp、Antigravity、Continue、Cortex、Crush、Devin、Droid、Forgecode、Goose、Junie、Kilo、Kiro、Kode、Mar'sCode、Mistral Vibe、Mux、OpenCode、OpenHands、Pi、Qoder、Rovodev、Roo、Tabnine、Tinycloud、Trae、Warp、Windsurf、Zed、Zencoder、Zenflow、Neovate、Pochi、Adal 等 — `install.sh` 明确支持 40 个;`npx skills` CLI 生态系统涵盖 60+。

### 手动安装(若你想要更多控制)

```bash
# 克隆
git clone https://github.com/lora-sys/ai-engineering-harness.git
cd ai-engineering-harness

# 安装到所有 Agent(交互式选择目标)
./install.sh

# 安装到指定 Agent
./install.sh --target codex
./install.sh --target claude

# 一次性铺到所有可写目录
./install.sh --all

# 卸载
./install.sh --uninstall
```

`install.sh` 支持的 target(完整列表 38 个):
`codex` · `claude` · `agents` · `cursor` · `gemini` · `qwen` · `opencode` · `grok` · `hermes-agent` · `hermes` · `aider-desk` · `augment` · `bob` · `codebuddy` · `commandcode` · `continue` · `crush` · `devin` · `factory` · `forge` · `goose` · `iflow` · `junie` · `kilocode` · `kiro` · `kode` · `marscode` · `mux` · `neovate` · `openhands` · `pi` · `pochi` · `roo` · `snowflake` · `tabnine` · `trae` · `trae-cn` · `vibe` · `zencoder` · `adal`

#### 一次性装齐 3 个 skill(推荐)

`install.sh` 只装你点名的 skill。要一次装齐 3 个兄弟:

```bash
# 精简装(只 SKILL.md + meta.json)
bash /path/to/ai-engineering-harness/scripts/install-all-skills.sh

# 完整装(workflows/ + references/ + templates/ 也复制)
bash /path/to/ai-engineering-harness/scripts/install-all-skills.sh --fat

# 14 个目标全检查
bash /path/to/ai-engineering-harness/scripts/install-all-skills.sh --status
```

把 `ai-engineering-harness` + `build-agent-app` + `frontend-creative` 装到全部 14 个 agent 平台(Codex / Claude / Cursor / Gemini / Qwen / OpenCode / Grok / Hermes / AiderDesk / Augment / Trae 等),让 Codex 能 `@build-agent-app` 和 `@frontend-creative`(不只是 `@ai-engineering-harness`)。

### 管理已有项目 · Managing existing projects

Harness 在不断演进 — v1.0 加了闭环,v1.4 加了 `sync-project.sh`,v1.7 加了 GHA + 4 套主题,v1.8 加了 `--auto` + `register-existing.sh`。**已经被这个 skill 接管的项目需要重跑 sync 才能拿到新功能。**

三条路径,全部幂等,全部非破坏性:

```bash
# 1. 更新 harness 自身
npx -y skills update lora-sys/ai-engineering-harness -g

# 2. 更新单个已接管的项目
bash /path/to/ai-engineering-harness/scripts/sync-project.sh --project-dir ~/projects/my-app --auto

# 3. 一次性更新所有项目
bash /path/to/ai-engineering-harness/scripts/register-existing.sh ~/repos
```

**设计上非破坏性** — 迁移从不覆盖用户内容:
- `compact-report.json` 永不覆盖(只在缺失时创建)
- AGENTS.md 的 fenced block(用 `<!-- HARNESS:START name -->` 标记)有边界 — harness 只管 block,其它都归用户
- `.github/ISSUE_TEMPLATE/` 只在缺失时复制
- `.harness-state.json` 重跑只改 `last_synced_at` 时间戳

### 典型用法

#### 1. 从 PRD 启动新项目

```
Use $ai-engineering-harness to bootstrap this repo from PRD.md.
```

`workflows/00-project-bootstrap.md` 会接管:在 repo 里创建 `docs/`、`memory/`、`PROJECT_STATUS.md`、Issue / PR 模板、CI 配置、ADR 模板、Phase 总结模板与首批 Issue。

#### 2. 接手老项目并补齐工程基础设施

```
Use $ai-engineering-harness. Read PROJECT_STATUS.md and continue the next Todo.
```

Harness 会先盘点代码、再决定是否需要 bootstrap,然后回到 Kanban 当前列。

#### 3. 把一个 Issue 推到 merged

```
Use $ai-engineering-harness to take Issue #17 from Planning to Done.
```

包括:写实施计划 → 分派到前端/后端/数据库 Agent → 拉分支与 Worktree → 实现 → 自测 → Draft PR → CI → 冷启动审查 → 修循环 → Evidence 闸门 → 合并 → 阶段总结 → 记忆沉淀。

#### 4. 复盘一个失序的工程

```
Use $ai-engineering-harness to audit this repo: list open PRs older than 7 days, flag missing Evidence, and produce a recovery plan.
```

### 工作机制

#### Issue 必须齐全以下字段

Context / Goal / Scope / Non-Goal / Related Docs / Implementation Plan / Acceptance Criteria / Evidence Requirements / Reviewer Requirements / Owner / Estimate。Coordinator 不会在缺失字段的 Issue 上启动代码。

#### 上下文按 L0–L3 分层加载

- **L0 全局规则**(`AGENTS.md`、`ENGINEERING.md`、`CONTRIBUTING.md` 摘要)— 始终加载
- **L1 任务级**——当前 Issue、模块架构、相邻 ADR、验证标准
- **L2 按需**——相邻模块、最近阶段总结、接口契约
- **L3 深层**——只有在显式需要时才加载;PDF/图片/长报告必须先抽取结论

`agents/context-assembly.md` 会为每个 Agent 任务产出 `context-manifest.md`,审查员能审计"这个 Agent 看到了什么"。

#### 证据闸门

Done 不是"PR 合进去了",而是 `docs/evidence/<id>/` 里齐了:

- `change-summary.md` + `verification.md`(每条 AC 的 PASS/FAIL)
- 前端:`screenshots/`(桌面/平板/手机/空/错/加载六态)+ Playwright trace + Console 干净 + a11y 扫描
- 后端:API trace、异常覆盖、鉴权负面用例、性能基线
- 数据库:migration + rollback、Pre/Post stats、Sample rows
- 审查:`review-<role>.md` × ≥ 2 + `fix-tasks.md` Aggregator ✅
- CI:绿;无 Critical/High 阻断

#### 人工审批闸门

涉及 鉴权/授权模型 / 数据库 schema(含数据迁移) / 生产密钥或付费 API / 发布版本 时,Coordinator 会主动 `request_user_input` 或停在 PROJECT_STATUS 上等待 `Waiting for Approval`。

#### 文件系统消息总线

每个 Session 在 `sessions/<id>/` 下维护 `status.md`、`plan.md`、`execution.md`、`review.md`、`summary.md`。Agent 之间不靠聊天历史,只靠这些文件 + 各 Issue 的 Evidence 目录。新 Session 启动时 Coordinator 读取 `memory/` + 上一次 `summary.md` 恢复未完成工作。

### 何时不要用这个 Skill

- 单文件一次性修改
- 不会落到仓库的原型
- 你想自己写代码、不想 Agent 介入

### 仓库结构

```
.
├── SKILL.md                    # Agent 加载入口
├── README.md                   # 你看到的这份
├── LICENSE
├── .gitignore
├── install.sh                  # 全局安装脚本(支持 38 个 CLI Agent)
├── agents/                     # 18 类 Agent 角色定义
├── workflows/                  # 9 个工作流
├── templates/                  # 16 套模板(Issue / Plan / PR / Review / Evidence / Phase / ADR 等)
├── checklists/                 # 6 份验收清单
├── references/                 # 6 份深化文档(L0–L3、索引、Worktree、Agent spawn)
├── examples/                   # 6 份已填写示例
└── scripts/                    # new-session / new-evidence / new-worktree / refresh-index / changelog
```

### 展示 · Showcase

这一节是**真实 e2e 跑出来的产物**(`feature/15-install-status`,commit `4f311e2`,merge `f5b26d1`),不是为 README 编出来的。

#### 闭环 (v1.2.0)

![Closed loop](assets/closed-loop-v1.2.svg)

黄色高亮的是 v1.2.0 新增。红色 CI 闸门是 harness 最强的 gate —— 比对抗式审查还强,因为 red CI 是唯一机械可观察的失败。

#### context bundle 真样

`scripts/context-bundle.sh` 一次产出 18 KB / 281 行 markdown,子代理读它就不用各自 `git log / ls / find`。并行 ~5.6s,串行 ~8.0s。

#### compact report 真样

`scripts/compact-report.sh` 产出 374 字节 JSON,Coordinator 读这个比读 20 KB 实现叙事快两个数量级。Test 状态从 `test-results/*` 自动扫,任何 FAIL 标记胜出。

#### 自审里说了哪些实话

- `--status` 第一版有 bug:在空环境跑会把 `settings.json` 创建出来。是 7 个手动测试抓到的,删了文件创建那行才修好。
- Adversarial review 我只做了一行自问自答。真生产里得 spawn `bug-hunter` + `behavior-reviewer`。
- 没有真的开 GitHub Issue #15 —— 在自己仓库上很容易跳过这一步。

完整自审:[docs/evidence/15/self-review.md](./docs/evidence/15/self-review.md)。

### 路线图 · Roadmap

三段:**Active**(本周在做的)、**Backlog**(计划中)、**Done**(已发布)。

#### Active

_(Roadmap Part 1 和 Part 2 已完成 — 见 Done 段。)_

#### Backlog

- frontend-creative: 4 套主题变体(Cyberpunk / Minimal Gallery / Retro Acid / Future 3D)
- frontend-creative: iteration-log 模板(防"AI 越改越普通")
- frontend-creative: Awwwards 风格自评清单
- 主 harness: 给 `scripts/release-prep.sh` 加 `gh release` 自动化
- 主 harness: GHA workflow 跑 `scripts/run-tests.sh`(目前只有本地)

#### Done

- **v1.7.0** — GHA workflow (`test.yml` runs harness tests on every PR) + `scripts/release.sh` (one-command release flow) + 4 frontend-creative theme variants + Awwwards / anti-drift gates wired into workflows; 69 bats tests
- **v1.6.0** — `skills/frontend-creative/` sibling skill (Awwwards-grade creative web UIs) + 2 `install.sh` bug fixes; 66 bats tests
- **v1.5.0** — PR intake flow (`workflows/09-pr-intake.md`) + Local-first principle (SKILL.md #9) + decision matrix; closes Roadmap Part 1
- **v1.4.0** — `scripts/sync-project.sh` + 58 个 bats 测试
- **v1.3.0** — bats 测试套件(38→58)+ 修 3 个 install-session-hook 回归
- **v1.2.1** — `install-session-hook.sh --status` + README Showcase 真实 e2e 产物
- **v1.2.0** — `context-bundle.sh` + `compact-report.sh`
- **v1.1.0** — `.claude/SESSION.md` 的 SessionStart hook(只读)
- **v1.0.x** — CI 作为阻塞闸门、validators、check-templates、install-session-hook、D-013 发版流程修复

### 许可



MIT — 见 [LICENSE](./LICENSE)。

---
## Repo identity

- **origin**: `git@github.com:lora-sys/ai-engineering-harness.git`
- **branch**: `main`
- **HEAD**: `765ecd0`
- **tag**: `v1.2.0`
- **working tree**: clean

## Recent commits (last 20)

765ecd0 feat(scripts): context-bundle.sh + compact-report.sh (v1.2.0)
5a65b7a feat(hooks): SessionStart hook auto-reads .claude/SESSION.md (v1.1.0)
...

## Harness roster

### Workflows
  - `00-project-bootstrap.md` — Workflow — Project Bootstrap
  - `01-feature-delivery.md` — Workflow — Feature Delivery
  ...

### Agents
  - `architecture-reviewer`
  - `backend`
  - `bug-hunter`
  - `coordinator`
  ...
```

Wall time: ~5.6 s parallel / ~8.0 s sequential. Sections run in parallel as backgrounded subshells. Source: [references/context-bundle.md](./references/context-bundle.md).

#### Phase 5 — compact report (real)

`scripts/compact-report.sh --evidence-dir docs/evidence/15 --branch feature/15-install-status --agent backend` produces a 374-byte JSON the parent Coordinator parses instead of re-reading the 20 KB implementation narrative:

```json
{
  "agent": "backend",
  "branch": "feature/15-install-status",
  "commit": "4f311e2",
  "files": 2,
  "test": "pass",
  "blockers": ["needs review"],
  "evidence_paths": [
    "compact-report.json",
    "implementation-report.md",
    "test-results/manual.log"
  ],
  "evidence_size_bytes": 1407,
  "report_md": "implementation-report.md",
  "generated_at": "2026-07-13T10:08:44+08:00"
}
```

Test status auto-detected by grepping `test-results/*` (any FAIL marker wins over PASS). Source: [references/compact-report.md](./references/compact-report.md).

#### Honest self-review of the e2e run

What worked:

1. `context-bundle.sh` gave the implementer everything they needed in one read — no redundant exploration.
2. Worktree discipline (`git worktree add ... -b feature/...`) kept `main` untouched.
3. The harness's own validators (validate-meta.sh + check-templates.sh) caught the 2 script-syntax errors during development.
4. `compact-report.sh` produced a structured 374-byte summary the parent actually needs.

What friction showed up:

1. **Editing complex bash with Python subshells is fragile** — my first rewrite attempt failed silently due to heredoc quoting. Lesson: write Python to a file first, don't inline.
2. **`--status` initially created `settings.json` on a fresh machine** — the file-creation check ran before the action switch. The 7-test self-test caught it. Without the test, that would have shipped as a side effect.
3. **Adversarial review was one-line self-Q&A** — in production I'd spawn `bug-hunter` and `behavior-reviewer`. Solo-maintainer mode is harder to do honestly.
4. **GitHub Issue #15 doesn't exist** — the harness workflow says every change starts as an Issue. Working on your own repo makes that easy to skip.

Full self-review: [docs/evidence/15/self-review.md](./docs/evidence/15/self-review.md).

#### What this is NOT

- Not a screenshot of a polished demo. The artifacts above are from a real `git log` / `ls` / `cat` of the working tree at commit `4f311e2`.
- Not a green-tick theatre. The honest self-review section above names real gaps.
- Not a replacement for adversarial review. The e2e ran with solo self-review; in production you'd run `bug-hunter` + `behavior-reviewer` per the harness's closed loop.

### Roadmap

Three lanes: **Active** (in progress this week), **Backlog** (planned, queued), **Done** (shipped).

#### Active

_(Roadmap Part 1 and Part 2 done — see Done section.)_

#### Backlog

- Frontend-creative: theme variants (Cyberpunk / Minimal Gallery / Retro Acid / Future 3D)
- Frontend-creative: iteration-log template (prevents "AI 越改越普通")
- Frontend-creative: Awwwards-style review checklist
- Harness: add `gh release` automation to `scripts/release-prep.sh`
- Harness: GHA workflow that runs `scripts/run-tests.sh` on every PR (currently local-only)

#### Done

- **v1.7.0** — GHA workflow (`test.yml` runs harness tests on every PR) + `scripts/release.sh` (one-command release flow) + 4 frontend-creative theme variants + Awwwards / anti-drift gates wired into workflows; 69 bats tests
- **v1.6.0** — `skills/frontend-creative/` sibling skill (Awwwards-grade creative web UIs) + 2 `install.sh` bug fixes; 66 bats tests
- **v1.5.0** — PR intake flow (`workflows/09-pr-intake.md`) + Local-first principle (SKILL.md #9) + decision matrix; closes Roadmap Part 1
- **v1.4.0** — `scripts/sync-project.sh` + 58 bats tests (sync already-bootstrapped projects)
- **v1.3.0** — bats test suite (38→58 tests) + 3 install-session-hook regressions fixed
- **v1.2.1** — `install-session-hook.sh --status` + README Showcase with real e2e artifacts
- **v1.2.0** — `context-bundle.sh` + `compact-report.sh` (parallel dump + structured JSON summary)
- **v1.1.0** — SessionStart hook for `.claude/SESSION.md` (read-only)
- **v1.0.x** — CI as a blocking gate, validators, check-templates, install-session-hook, D-013 release-process fix

### License

MIT — see [LICENSE](./LICENSE).

---


## 使用指南 · Usage Guide

> 这一节把"装上后怎么用"讲透。先看 4 个最高频的指令,再看心法,最后看进阶与反模式。
>
> This section makes "how to actually use it" concrete. Read the 4 high-frequency invocations first, then principles, then advanced usage and anti-patterns.

### 4 个最高频指令 · Top 4 invocations

#### ① 从 PRD 启动新项目 · Bootstrap a new project from a PRD

```
Use $ai-engineering-harness to bootstrap this repo from PRD.md.
```

Coordinator 会按 `workflows/00-project-bootstrap.md` 一次创建 `docs/{product,architecture,design,decisions}`、`memory/`、`PROJECT_STATUS.md`、`AGENTS.md` / `CLAUDE.md`、`DESIGN.md`、`ENGINEERING.md`、`TESTING.md`、`CONTRIBUTING.md`、`.github/ISSUE_TEMPLATE/`、`.github/PULL_REQUEST_TEMPLATE.md`、Phase 总结模板与首批 Issue。

The Coordinator runs `workflows/00-project-bootstrap.md`, creating the full doc tree, memory, status, project meta-docs, GitHub Issue / PR templates, and the first round of Issues.

#### ② 接续已存在的工作 · Resume interrupted work

```
Use $ai-engineering-harness. Read PROJECT_STATUS.md and continue the next Todo.
```

它会读 `memory/` + 上一次 Session 的 `summary.md`,从中断处继续。

Reads `memory/` + the last Session's `summary.md` and picks up where you left off.

#### ③ 把单个 Issue 推到合并 · Take one Issue to merged

```
Use $ai-engineering-harness to take Issue #17 from Planning to Done.
```

走完整闭环:写 Plan → 在 Worktree 里分派 Frontend/Backend/Database Agent → 实现 → 自测 → Draft PR → CI → 冷启动对抗式审查(Bug Hunter + Behavior Reviewer + 必要时 Architecture/Security/UI Reviewer)→ 修循环 → Evidence Gate → 合入 → 阶段总结 → 记忆沉淀。

Walks the full closed loop: Plan → spawn Frontend/Backend/Database on isolated Worktrees → Implement → Self-test → Draft PR → CI → cold-start adversarial review (Bug Hunter + Behavior Reviewer, plus Architecture/Security/UI when warranted) → Fix loop → Evidence Gate → Merge → Phase summary → Memory write.

#### ④ 复盘 / 救火 · Audit or rescue

```
Use $ai-engineering-harness to audit this repo: list open PRs older than 7 days,
flag missing Evidence, and produce a recovery plan.
```

它盘点"现状 → 期望"的 Gap,转成一批自动归列的 Issue,并给出先做的 3 件事与执行顺序。

The Coordinator inventories the gap from "current" to "expected", files a batch of Issues on the kanban, and surfaces the first three actions with sequencing.

### 使用心法 · Operating principles

| # | 原则 · Principle | 为什么 · Why |
|---|---|---|
| 1 | **信任证据,不信任"看起来好了" · Trust evidence, not vibes** | Coordinator 不会因为"本地测试过了"就合并。它要看到 `docs/evidence/<id>/` 里所有 `verification.md` 的 AC 行 PASS,且 CI 绿、≥ 2 名审查员 ✅、Aggregator ✅。Missing one → not Done. |
| 2 | **冷启动审查 · Cold-start reviews** | Reviewer 只读 Issue + Plan + PR diff + Evidence,**不读实现者的聊天或解释**。这避免了"自己说服自己"。 |
| 3 | **Issue 是工作单元 · Issues are the unit of work** | 没有 Issue 不开工。Issue 必须有 Context / Goal / Scope / Non-Goal / Related Docs / Plan / AC / Evidence Reqs / Reviewer Reqs / Owner / Estimate。 |
| 4 | **Worktree 隔离 · Worktree isolation** | 一个 Issue = 一个 Owner = 一个 Worktree = 一个分支。多个并行 Owner 互不干扰,只在冲突时进 Conflict Resolver。 |
| 5 | **上下文按 L0–L3 加载 · L0–L3 context control** | 默认不加载 `docs/` 全文。让 `agents/context-assembly.md` 按任务产出 `context-manifest.md`,只给 Agent 当前必需的最小可信上下文。 |
| 6 | **人工审批闸门 · Human Approval Gate** | 涉及 鉴权 / 数据库 schema / 生产密钥 / 付费 API / 发布版本 时,Coordinator 会主动 `request_user_input` 并暂停。它不会代你做这些判断。 |
| 7 | **记忆是项目状态,不是聊天 · Memory is project state, not chat** | 稳定结论写到 `docs/` 与 `memory/`;对话历史不留。每个 Phase 结束后 Coordinator 跑 `workflows/06-phase-summary.md` 沉淀。 |
| 8 | **CI/CD 是阻塞闸门,不是检查项 · CI/CD is a blocking gate** | Owner 自首个 commit 起盯 CI;Coordinator 阻止进入 Phase 8 / 合并 / Done,直到 CI 绿。Red CI ⇒ `workflows/04-ci-recovery.md`,同一类失败 ≥2 次 ⇒ `ci`-tagged Issue + `memory/lessons.md` 一行。详见 `references/cd-monitoring.md`。 |
| 9 | **本地优先 · Local-first** | PR 提议的代码本地已有等价实现时,**不要直接合并**:留评论指路本地路径,让作者对齐本地版本或提议真正增量的东西。本地版本不动。对应 `workflows/09-pr-intake.md` Step 2。 |

### 典型指令清单 · Canonical invocations

```text
# 启动
Use $ai-engineering-harness to bootstrap this repo from PRD.md.

# 接续
Use $ai-engineering-harness. Read PROJECT_STATUS.md and continue the next Todo.

# 单 Issue 推动
Use $ai-engineering-harness to take Issue #17 from Planning to Done.

# 复盘 / 救火
Use $ai-engineering-harness to audit this repo and produce a recovery plan.

# 跨 CLI 接力(从 Claude 切到 Grok,聊天历史没用,落盘状态才行)
Use $ai-engineering-harness. I'm continuing from another agent. Read
memory/project-memory.md and sessions/<last-id>/summary.md, then continue.

# 只取一个 Phase 总结,而不打开所有 docs/
Use $ai-engineering-harness. Summarize the latest phase.

# 把多个 Issue 并行分派给前端 / 后端 / 数据库 Agent
Use $ai-engineering-harness to spawn parallel Owners for Issue #20, #21, #22.
```

### 进阶用法 · Advanced usage

#### 30 秒拉起一个新项目

```bash
mkdir my-saas && cd my-saas
git init
echo "# My SaaS" > README.md
git add . && git commit -m "feat: init"

# 进入任意 CLI(Codex / Claude / Grok / Cursor / Gemini ...)
# Use $ai-engineering-harness to bootstrap this repo from PRD.md
```

Coordinator 会生成目录骨架、首轮 Issue、ADR 模板、CI 工作流占位,然后在 `PROJECT_STATUS.md` 上写 "Phase 0 / Bootstrap — Done"。

#### 接手老项目,补齐工程基础设施

```
Use $ai-engineering-harness to take over this repo. Inventory the gap
between current state and harness layout; file Issues for the missing
pieces; do not edit code yet.
```

它先盘点 → 把差距落 Issue,再按 Issue 推进;**不会先去动业务代码**。

#### 跨 CLI 接力

Harness 的所有状态都落盘,**聊天历史不会丢**。从 Claude 切到 Grok 时:

```
Use $ai-engineering-harness. I'm continuing from another agent. Read
memory/project-memory.md and the latest sessions/<id>/summary.md.
```

#### 让 Agent 并行做多件事

```
Use $ai-engineering-harness to plan and dispatch Issue #18 (frontend),
#19 (backend), #20 (database) in parallel Worktrees.
```

Coordinator 会分别拉 `feature/18-...`、`feature/19-...`、`feature/20-...` 三个 Worktree,每个 Owner 独立推到 PR。冲突时由 Conflict Resolver 处理,**不会自动覆盖**。

#### 在 CI 出错时让它自愈

```
CI is red on PR #N. Use $ai-engineering-harness to recover.
```

走 `workflows/04-ci-recovery.md`:60 秒分类(flaky / 真缺陷 / lint / 集成 / infra)→ 派 Owner Agent 修复 → 重新跑 CI → 重新走 Reviewer。

### 不要这样用 · Anti-patterns

| 反模式 · Anti-pattern | 为什么不行 · Why it fails | 应该做 · Do this instead |
|---|---|---|
| 缺字段的 Issue 上让它"先做着" | Coordinator 不会启动。 | 补齐字段(模板就在 `.github/ISSUE_TEMPLATE/`)。 |
| 直接改 `main` / `master` | 拒绝。Worktree 是硬要求。 | `git worktree add ../proj-issue-<id> -b feature/<id>-<slug> main` |
| 让实现者同时"自审" | 审查员**必须冷启动**。 | 让它 spawn 一个独立 Reviewer Agent,只喂 Issue + Diff + Evidence。 |
| 把 100 页 PDF 当成整个 Spec 直接喂 | 上下文会被垃圾塞满。 | 用 `agents/context-assembly.md` 抽出相关章节再喂。 |
| "我觉得可以合并" | 不会合并。要 Evidence Gate 全绿 + Aggregator ✅。 | 等 Coordinator 自己报 Ready。 |
| 在它做事的中间打断催 | 打断 = 状态不一致。 | 看 PROJECT_STATUS.md / TaskList,不要直接抢方向盘。 |
| 把它当一次性 coding prompt | 它不是 Prompt,是 Harness。 | 用它管产品,不是写一行代码。 |

### 适用 / 不适用 速查 · When (not) to use

| 场景 · Scenario | 用 Harness? · Use it? |
|---|:---:|
| 把一个 PRD 落地成 MVP | ✅ 必须 · Mandatory |
| 多 Issue 并行开发 | ✅ 必须 · Mandatory |
| 接手老项目、清理技术债 | ✅ 强烈推荐 · Strongly recommended |
| 复盘一个失序的 repo | ✅ 强烈推荐 · Strongly recommended |
| 跨团队 / 跨 CLI 协作 | ✅ 推荐 · Recommended |
| 改一行 typo / 文案 / 配置 | ❌ 不要 · Skip |
| 一次性脚本 / 一次性原型 | ❌ 不要 · Skip |
| 只是想聊架构想法 / 解释概念 | ❌ 不要 · Skip |

### 维护 · Maintenance

```bash
# 升级到最新版本
npx -y skills update lora-sys/ai-engineering-harness -g

# 查看当前装的版本
npx skills list -g

# 在项目仓库里加 git commit hook,自动维护 docs/ 的索引
cat > .githooks/post-commit <<'HOOK'
#!/usr/bin/env bash
bash <(curl -fsSL https://raw.githubusercontent.com/lora-sys/ai-engineering-harness/main/scripts/refresh-index.sh)
HOOK
chmod +x .githooks/post-commit
git config core.hooksPath .githooks
```

每个 Phase 完成后,Coordinator 会自动跑 `workflows/06-phase-summary.md` + `workflows/08-memory-evolution.md`,把"什么是真的学到的"沉淀进 `memory/<role>-memory.md`。下次有新 Session 启动,新 Agent 会先读这些再开工。

After each Phase, the Coordinator automatically runs `workflows/06-phase-summary.md` and `workflows/08-memory-evolution.md`, promoting stable lessons into `memory/<role>-memory.md`. Next Session, new Agents read these before starting work.

### 进阶阅读 · Further reading

- [`SKILL.md`](./SKILL.md) — Agent 加载的入口全文 · Entry document loaded by every agent
- [`agents/`](./agents/) — 18 类 Agent 角色 · 18 agent personas
- [`workflows/`](./workflows/) — 9 个工作流 · 9 closed-loop workflows
- [`templates/`](./templates/) — 16 套模板 · 16 templates (Issue / Plan / PR / Review / Evidence / Phase / ADR / ...)
- [`checklists/`](./checklists/) — 6 份验收清单 · 6 acceptance checklists
- [`examples/`](./examples/) — 6 份已填写示例 · 6 filled samples

## Tables / 表格

| Compatibility / 兼容性 | Install path / 安装路径 | Status after one-liner / 一行安装后状态 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | ✅ |
| Codex | `~/.codex/skills/` | ✅ |
| Cursor | `~/.cursor/skills/` | ✅ |
| Gemini CLI | `~/.gemini/skills/` | ✅ |
| Qwen / Qoder | `~/.qwen/skills/` | ✅ |
| Grok CLI | `~/.grok/skills/` | ✅ |
| OpenCode | `~/.config/opencode/skills/` | ✅ |
| Hermes-Agent | `~/.hermes/hermes-agent/skills/` | ✅ |
| Hermes | `~/.hermes/skills/` | ✅ |
| Aider Desk | `~/.aider-desk/skills/` | ✅ |
| Augment | `~/.augment/skills/` | ✅ |
| Bob | `~/.bob/skills/` | ✅ |
| Codebuddy | `~/.codebuddy/skills/` | ✅ |
| Commandcode | `~/.commandcode/skills/` | ✅ |
| Continue | `~/.continue/skills/` | ✅ |
| Crush | `~/.config/crush/skills/` | ✅ |
| Devin | `~/.config/devin/skills/` | ✅ |
| Factory | `~/.factory/skills/` | ✅ |
| Forge | `~/.forge/skills/` | ✅ |
| Goose | `~/.config/goose/skills/` | ✅ |
| iFlow | `~/.iflow/skills/` | ✅ |
| Junie | `~/.junie/skills/` | ✅ |
| KiloCode | `~/.kilocode/skills/` | ✅ |
| Kiro | `~/.kiro/skills/` | ✅ |
| Kode | `~/.kode/skills/` | ✅ |
| Marscode | `~/.marscode/skills/` | ✅ |
| Mux | `~/.mux/skills/` | ✅ |
| Neovate | `~/.neovate/skills/` | ✅ |
| OpenHands | `~/.openhands/skills/` | ✅ |
| Pi | `~/.pi/agent/skills/` | ✅ |
| Pochi | `~/.pochi/skills/` | ✅ |
| Roo | `~/.roo/skills/` | ✅ |
| Snowflake Cortex | `~/.snowflake/cortex/skills/` | ✅ |
| Tabnine | `~/.tabnine/skills/` | ✅ |
| Trae | `~/.trae/skills/` | ✅ |
| Trae-CN | `~/.trae-cn/skills/` | ✅ |
| Vibe | `~/.vibe/skills/` | ✅ |
| Zencoder | `~/.zencoder/skills/` | ✅ |
| Adal | `~/.adal/skills/` | ✅ |
| `.agents/` (unified) | `~/.agents/skills/` | ⏳ pending OS-level mount-RW on this system |


---



## Troubleshooting · 安装常见问题

### "I see only SKILL.md, not workflows/ or templates/"

This is a known quirk of the Vercel `npx skills` CLI: it ships a *thin* canonical install
(`~/.agents/skills/<name>/SKILL.md` only) and lets per-agent installs decide between
copy or symlink. Symlinked agents like **Claude Code** then see nothing but `SKILL.md`
because they read through the thin canonical.

**Workarounds** (in order of preference):

1. **Fat install — git clone + symlink everything**:

   ```bash
   bash <(curl -fsSL https://raw.githubusercontent.com/lora-sys/ai-engineering-harness/main/install.sh) --fat-install
   ```

   Or, if you have the repo cloned:

   ```bash
   ./install.sh --fat-install
   ```

   This `git clone`s the repo to `/tmp/ai-engineering-harness-fat` and replaces every
   per-agent install with a symlink to the full bundle. After this, every agent that
   allows a writable parent dir will see `workflows/`, `templates/`, `agents/`, etc.
   Use `--clonedir <path>` to pick a different clone target.

2. **Read the docs from the GitHub repo**: <https://github.com/lora-sys/ai-engineering-harness/tree/main>

3. **Use git-copilot style — clone and symlink one agent**:

   ```bash
   git clone --depth 1 https://github.com/lora-sys/ai-engineering-harness.git /tmp/aeh
   ln -s /tmp/aeh ~/.claude/skills/ai-engineering-harness
   ```

### Why didn't my `npx skills add` install the bundle?

We did everything right on our end (the repo has `meta.json`, 10 topics, MIT license,
proper `SKILL.md` frontmatter), but the canonical install under
`~/.agents/skills/ai-engineering-harness/` ends up containing only `SKILL.md`. That's
the Vercel CLI's design. We're tracking a fix at
<https://github.com/vercel-labs/skills/issues/1630>.


## Scripts and tooling · 工具脚本

The repo ships with three helper scripts. All are safe to run from anywhere; they're the bones of every maintenance step.

### `scripts/validate-meta.sh` — schema check for `meta.json`

```bash
scripts/validate-meta.sh                # default: ./meta.json, exit 0/1/2
scripts/validate-meta.sh --strict       # also fail on warnings
scripts/validate-meta.sh --json        # one-line JSON for CI
```

Validates `meta.json` against the embedded schema (id, name, description, category, priority, tags, install map, agents_supported, license, repository, entry). Returns exit 0 on success, 1 on errors, 2 on missing/invalid JSON. Designed to plug into PR pre-commit and CI.

### `scripts/changelog-auto.sh` — half-automated CHANGELOG from git + `gh`

```bash
scripts/changelog-auto.sh                  # preview to stdout (default)
scripts/changelog-auto.sh --write         # write to ./CHANGELOG.md
scripts/changelog-auto.sh --append        # emit only versions newer than the latest documented
scripts/changelog-auto.sh --since-tag v0.1.3   # filter to versions ≥ tag
```

Categorizes conventional-commit subjects into Keep-a-Changelog sections (Added / Changed / Fixed / Docs / Performance / Tests / Maintenance / CI / Build / Style), fetches the **What's new** intro from each GitHub Release via `gh release view`, and emits an index. `--append` is the safe default for ongoing maintenance — it preserves human-curated entries and only auto-fills new versions.

### Existing tools

- `scripts/new-session.sh` — `sessions/<id>/{status,plan,execution,review,summary}.md`
- `scripts/new-evidence.sh` — `docs/evidence/<id>/{change-summary,verification,…}`
- `scripts/new-worktree.sh` — `git worktree add ../<repo>-issue-<id>`
- `scripts/refresh-index.sh` — `docs/.index/{manifest,freshness,relations}.json`



## Companion skills

This repo ships a small skill family, not just one skill. Both skills install
into the same per-CLI-agent directory under different folder names and are
independently invokable.

### `build-agent-app` (sibling · at `skills/build-agent-app/`)

The **Agent App Architect**. Trigger when the user wants to design an agent app
(greenfield from a PRD), integrate an existing one, or fix a broken one.

```text
Use $build-agent-app to design a code-review agent from PRD.md
Use $build-agent-app to integrate /path/to/agent-app into my project
Use $build-agent-app to diagnose why /path/to/agent is misbehaving
```

Workflow: `references/decision-0.md` ("is this even an agent?") →
Agent Contract → Harness Spec → hand off back to `$ai-engineering-harness` for
implementation. Pairs with this skill; both share the kernel **agent = model + harness**.

### Install (covers the family)

```bash
bash install.sh                                  # both skills to every TARGET (default)
bash install.sh --skill build-agent-app          # only the sibling
bash install.sh --fat-install --skill all        # git clone + symlink both skills
```

The `npx skills add lora-sys/ai-engineering-harness -g --all` command still
installs only the primary skill (its own canonical). For the sibling, run the
above `bash install.sh --skill build-agent-app` after.

### When to call which skill

| Want to … | Trigger |
| --- | --- |
| Build a software product (engineering org) | `$ai-engineering-harness` |
| Design / take over / refactor an **agent app** | `$build-agent-app` |
| Both — agent app with engineering-grade evidence gates | `$build-agent-app` designs, then hands off to `$ai-engineering-harness` |


## Discoverability · 收录与发现

This skill is automatically aggregated by [Vercel's `skills.sh`](https://skills.sh/) index — a public registry for AI agent skills. Once GitHub's crawler picks up the topics + SKILL.md metadata here, the install command shows up in skill search results.

To help the crawler (or anyone running the `npx skills find` CLI on the user machine):

```bash
# Tag-related search (works locally)
npx -y skills find ai-engineering-harness --owner lora-sys

# Browse by topic (when on the skills.sh web UI)
# Search: multi-agent, code-review, evidence, skills
```

If you fork or extend this skill, keep these GitHub fields intact:

| Field         | Why                                                              |
| ------------- | ---------------------------------------------------------------- |
| Topics        | `ai-engineering`, `multi-agent`, `skills`, `code-review`, etc.    |
| Description   | Begins with "AI-native software engineering organization harness… |
| License       | MIT — keeps it redistribution-friendly                            |
| `SKILL.md`    | YAML frontmatter `name` + `description` is what the indexer reads|
