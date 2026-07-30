# 案例库 · Case Studies

接管前后对比。每个案例包含：接手前状态、Harness 做了什么、接手后状态、可量化的结果。

每个案例都标注类型。**真实**案例的每个数字都能追到一个 commit 或一个文件；
**示意**案例展示的是"接管应该长什么样"，数字是设计目标而不是测量值。

| 案例 | 类型 | 证据 |
|------|------|------|
| 1 · 从"能跑的代码"到"可验证的交付" | 示意 | 数字为设计目标，无公开仓库可核对 |
| 2 · install-session-hook 自审 | **真实** | [`docs/evidence/15/`](../evidence/15/) · commit `4f311e2` |
| 3 · Dashboard 一键接管 | 示意 | 输出**形态**取自真实 Quick Scan 的 JSON 结构；findings 与分数为构造 |
| 4 · 测试通过 ≠ 测试有效 | **真实** | commits `9cbff11`、`1c9900f` |
| 5 · 绿色的 CI 骗了我们 | **真实** | commit `f92fd53` · [`.github/workflows/test.yml`](../../.github/workflows/test.yml) |

---

## 案例 1：从"能跑的代码"到"可验证的交付"

> **⚠️ 这是示意案例。** 它展示的是一次接管**应该**产出什么形态的变化，
> 数字（0 → 47 个测试、Chaos 35 → 87）是设计目标，不是从某个真实项目测出来的。
> 没有公开仓库可以核对。想看每个数字都能追到 commit 的案例，看案例 2、4、5。

> 一个内部工具项目。AI 花了 3 天写完了，看起来能跑，但没有测试、没有 CI、没有文档。

### 接手前

| 维度 | 状态 |
|------|------|
| 测试 | 0 个 |
| CI | 无 |
| 代码审查 | 无 |
| 文档 | README 一行 |
| 分支策略 | 直接 push 到 main |
| 已知问题 | 3 个 TODO、1 个硬编码密钥 |
| Chaos Score | **35 / 100 (F)** |

### Harness 做了什么

1. **Bootstrap** → 创建 `docs/`、`memory/`、`PROJECT_STATUS.md`、Issue/PR 模板
2. **Quick Scan** → 自动发现 3 个 TODO、1 个硬编码 API key、12 个源文件无测试
3. **Issue 化** → 每个发现变成可追踪的 Issue（有 AC、有 Owner、有 Estimate）
4. **分派** → 后端 Agent 写测试 + 修复密钥，前端 Agent 补截图，QA Agent 产 Evidence
5. **对抗式审查** → Bug Hunter + Behavior Reviewer 冷启动审查
6. **Evidence Gate** → 每条 AC PASS + CI 绿 + 2 Reviewer Approved

### 接手后

| 维度 | 状态 |
|------|------|
| 测试 | 47 个（单元 + 集成） |
| CI | GitHub Actions，每次 push 自动跑 |
| 代码审查 | ≥2 冷启动审查员 per PR |
| 文档 | `docs/architecture/`、`docs/decisions/`、`memory/` 完整 |
| 分支策略 | feature/ + worktree 隔离 |
| 已知问题 | 0 |
| Chaos Score | **87 / 100 (B)** |

### 核心教训

> "看起来能跑" ≠ "可验证地跑通"。AI 写代码的速度是人类 10 倍，但没有工程纪律，bug 密度也一样。

---

## 案例 2：install-session-hook 自审（Harness 接管的第一个 Issue）

> **✅ 真实案例。** 证据在 [`docs/evidence/15/`](../evidence/15/)，
> 实现是 commit `4f311e2`。下面每个数字都能在那个目录里核对。

> Harness 自己的 `install-session-hook.sh` 需要加 `--status` 命令。这个 Issue 走完整闭环，包括一次诚实自审。

### 接手前

- 脚本没有状态查询能力
- 没有自动化测试（只有手动日志）
- Adversarial review  skipped（solo 维护者模式）

### Harness 做了什么

| Phase | 动作 | 产出 |
|-------|------|------|
| Plan | `agents/plan` 写实施计划 | `docs/evidence/15/implementation-plan.md` |
| Implement | `agents/backend` 在 worktree 实现 | `+54/-2` 行，commit `4f311e2` |
| Self-test | 7 个手动测试 | `test-results/manual.log` |
| Evidence | `agents/qa` 产证据包 | context-bundle (281 行) + compact-report (374 字节) |
| Self-review | 诚实自审（5 条 friction） | `self-review.md` |

### 自审的 5 条实话

1. **"Tests" 是手写日志** — 不是真正的自动化测试
2. **Adversarial review 只有一行自问自答** — 生产环境需要 spawn 独立 Reviewer
3. **GitHub Issue #15 不存在** — 在自己的 repo 上容易跳过 Issue 流程
4. **Python + heredoc 编辑脆弱** — 第一次重写静默失败
5. **`--status` 意外创建 `settings.json`** — 被自测抓到，否则会作为副作用发布

### 可量化的结果

- 脚本从 0 状态查询 → 7 项状态报告
- 证据包：281 行 context bundle + 374 字节 compact report
- **诚实自审本身就是 Harness 最有价值的产物** — 因为它记录了"什么没做好"

---

## 案例 3：Dashboard 一键接管 —— 30 秒发现 chaos

> **⚠️ 这是示意案例，但要说清楚哪部分是真的。**
> **真的**：`curl http://localhost:4321/api/quick-scan` 这个端点真实存在，
> finding 的类别、severity 分级、返回的 JSON 结构都与 `.dashboard/parser.js`
> 的实现一致 —— 你现在就能在自己的仓库上跑出这个形状的输出。
> **构造的**：具体的文件路径（`src/config.ts:12` 等）、23 这个问题总数、
> Chaos Score 42。它们演示的是输出长什么样，不是某次真实扫描的结果。
> 顺带一提：案例里这些数字与 `skills/dashboard/workflows/03-quick-scan.md`
> 文档中的**举例**吻合，因为它们同源。

> 一个已经有 harness 基础结构的老项目（有 `AGENTS.md`、`docs/`），但已经 60 天没有更新。

### 接手前

```bash
# 运行 Quick Scan
curl http://localhost:4321/api/quick-scan
```

**结果：**

| 发现 | 严重程度 | 位置 |
|------|----------|------|
| 硬编码 AWS secret key | HIGH | `src/config.ts:12` |
| 3 个 try 块没有 catch | MEDIUM | `src/api.ts:45`, `src/api.ts:89`, `src/utils.ts:23` |
| 18 个源文件无测试文件 | MEDIUM | `src/` |
| 7 个 TODO 无 issue 链接 | LOW | 5 个文件 |
| 1 处重复代码块 (4 行) | MEDIUM | `src/helpers.ts` + `src/legacy.ts` |

**Chaos Score: 42 / 100 (D)**

### 一键导出接管报告

```bash
curl http://localhost:4321/api/quick-scan | jq '.issues[:5]'
# → 直接给出 Top 5 问题 + 文件位置 + 严重程度
```

### 30 秒接管对话

```
You: 这个 repo 接手要多久？
Harness: Quick Scan 已完成。
  Chaos Score: 42/100 (D)
  Top 5: 1 个硬编码密钥、3 处缺失错误处理、18 个文件缺测试、7 个孤儿 TODO、1 处重复代码。
  建议优先修密钥（安全），然后补测试（可靠性）。
  要我自动生成 Issue 并分派吗？
```

### 效果

| 指标 | Before | After |
|------|--------|-------|
| Quick Scan 时间 | — | 30 秒 |
| 发现的问题数 | 0（不知道有什么问题） | 23 个（分类 + 严重程度） |
| 介入决策 | "看着办" | 数据驱动：先修 HIGH，再补 MEDIUM |
| 首次 PR 时间 | 天/周（不知道从哪开始） | 小时（Issue 已列好） |

---

## 怎么用这些案例

规则很简单：**对外说的每个数字，都要能指向一个 commit。** 示意案例可以用来解释
*形态*，但不要把它们的数字当成战绩报出去 —— 那正是这份文档之前在做的事。

1. **推文 / V2EX** → 用案例 5 的「CI 全绿，本地 108 个测试里 23 个失败」。它有
   commit `f92fd53` 可查，而且这个反差本身就是钩子。
2. **知乎 / 博客** → 用案例 4 的变异测试叙事：把整段校验注释掉，测试套件依然全绿。
   讲"怎么发现自己的测试是装饰的"，比讲"我们有多少个测试"有说服力。
3. **演示** → 现场跑 Quick Scan。案例 3 的**输出形态**是真的，在观众自己的仓库上
   跑就能出真数字，不需要引用案例里那些构造值。
4. **README** → 只列有证据的案例（2、4、5），每条带上 commit 或证据目录的链接。
5. **不要**引用案例 1 的 35 → 87 或案例 3 的 42。它们是设计目标，没有出处；
   一旦有人问"哪个项目"，你就没有答案了。

---

## 征集真实案例

> 想要一个**外部**项目的真实接管案例。目前 5 个案例里有 3 个是真实的，
> 但全部来自 harness 自己的仓库 —— 自审有价值，但它不能替代别人的项目。

理想来源：

- 从"失控的 Vibe Coding"开始
- 有明确的 before/after 截图或数据
- 包含 Quick Scan 的 chaos score 变化

**征集**：如果你用 Harness 接管的项目愿意分享，开一个 Issue 或 PR 添加到这里。
唯一的硬要求和上面一样：**每个数字要能指向一个 commit、一个文件或一张截图。**
