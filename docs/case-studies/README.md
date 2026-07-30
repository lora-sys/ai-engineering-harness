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

## 案例 4：测试通过 ≠ 测试有效（Harness 自身，issue #9）

> **✅ 真实案例。** commits `9cbff11`、`1c9900f`。下面每个数字都注明出处。

> Harness 自己的 dashboard skill。README 声称 Quick Scan"生成可追踪的 Issue"，
> 而没有任何代码做这件事。修它的过程里，发现自己的测试套件有一部分是装饰。

### 接手前

| 维度 | 状态 | 可核对 |
|------|------|--------|
| vibe-signs 检测器 | 9 个，且第 9 个名字叫 "Intent mismatch" 而实现的是 dead-code-after-return | `9cbff11` commit 正文 |
| "生成可追踪的 Issue" | README 这样写，没有任何实现 | `9cbff11` commit 正文 |
| 接管时扫描 | 被问才答，且只给一个分数 | `9cbff11` commit 正文 |
| dashboard 测试 | 24 个，"全绿" | `git show 9cbff11~1:skills/dashboard/tests/dashboard.bats \| grep -c '^@test'` |

### Harness 做了什么

1. **第 10 个检测器 `intent-loss`** —— 三条规则：doc 以函数动词的反义词开头（MEDIUM）、
   `@param` 不在签名里（LOW）、`@returns` 但函数从不 return（LOW）。
   在 12 MB 第三方语料上测得 **0.34% flag rate**，唯一存活的 flag 是真缺陷；
   为两类真实假阳性加了 guard（doc 同时提到两个动词是在描述操作的两侧；
   lodash 风格的 `@param {string} The string to inspect.` 捕获的是散文不是参数名）。
2. **把第 9 个检测器改名成它实际做的事** —— dead-code-after-return。
3. **让扫描主动开口** —— bootstrap 增加 existing-repo 分支，要求扫描**不经询问**就运行，
   并且必须点名具体类别与最差位置。一个光秃秃的等级只是在告诉用户"你的仓库很差"，
   没告诉他该做什么。
4. **新增 `scan-to-issues.sh`** —— 按类别归并（一个类别一个 Issue；40 个 TODO 开 40 个
   Issue 是噪音不是 backlog），验收标准带可验证的退出条件，干跑是默认行为。

### 接手后

| 维度 | 状态 | 可核对 |
|------|------|--------|
| 检测器 | 10 个 | `parser.js` 编号注释 1–10（L1070–1247） |
| findings 归档 | 一条命令变成分类 Issue | `skills/dashboard/scripts/scan-to-issues.sh` |
| dashboard 测试 | 39 个，仓库共 123（`1c9900f` 之后 124） | 两条 commit 正文 |
| 验收方式 | 变异测试 | `9cbff11` commit 正文 |

### 核心教训

**这个案例的重点不是"多了一个检测器"，而是变异测试暴露了套件本身的缺陷。**

bats 1.13 下只有**最后一条命令**的退出码决定测试成败。中途一条裸 `[[ ... ]]` 失败会被
静默吞掉，`set -e` 也救不了 —— bats 在测试体内重置它。把 projectRoot 校验整段注释掉，
套件依然全绿。更糟的是：有一条**已发布**的断言方向与 secret 检测器的设计相反，
在本地"通过"，在 CI（bats 1.10）会失败。修法是引入会真正 exit 非零的
`assert_has` / `assert_lacks` / `assert_eq`，并把这个约束写在文件顶部。

另外两个 bug 都是**测出来的，不是读出来的**：

- 另一个 repo 的 dashboard 在预期端口应答，它的 findings 被当作本项目的报了出来 ——
  距离"把 Issue 开到错的仓库"只差一条命令。现在响应必须携带匹配的 `_meta.projectRoot`。
- `$!` 并不可靠地等于 node 的 PID（bash 会为重定向再 fork 一次），cleanup 杀错了进程，
  幸存者 reparent 到 init，然后用过期数据回答**后一次**运行。现在真实 PID 从端口持有者
  解析，cleanup 等端口真的安静下来，而不是相信 `kill` 是同步的。

一个月后 `1c9900f` 又修了同一类问题的另一面：`sync-project is idempotent` 把整个
`.harness-state.json` 做全文比对，包括 `last_synced_at` —— 那个字段的**职责**就是每次
sync 都变。它只在两次运行落在同一秒内才通过；实测 12 次里有 8 次跨秒失败。
这是 CI 最坏的失败形态：看起来像真回归，重跑就"好了"，于是信号被训练成噪音。

---

## 案例 5：绿色的 CI 骗了我们（Harness 自身，issue #13）

> **✅ 真实案例。** commit `f92fd53`，CI 配置见
> [`.github/workflows/test.yml`](../../.github/workflows/test.yml)。

> CI 全绿。本地 108 个测试里 23 个失败，而且套件永久挂住直到 15 分钟 job 超时。
> 两个都是真的 —— 因为用户实际执行的 shell 不在 CI 矩阵里。

### 接手前

| 维度 | 状态 |
|------|------|
| CI | 全绿 |
| 本地（macOS）| 85/108 通过，然后无限挂起 |
| CI 矩阵 | 只有 Linux runner，bash 5.x |
| 用户实际执行的 | macOS `/bin/bash` = **3.2.57** |

### 6 个 bash 3.2-only bug

每一个在 Linux bash 5.x 上都能正常解析并运行，所以 CI 一次也没看见过（编号同
`f92fd53` commit 正文 1–6）：

1. **`sync-project.sh` —— 在 macOS 上整个脚本无法运行**（exit 2）。bash 3.2 无法解析
   `$( )` 里含撇号的 heredoc；第 237 行的 `don't` 打断 lexer，而报错出现在 **39 行之后**。
   这**一个** bug 造成 23 个本地失败中的 **19** 个。
2. **`changelog.sh`** —— `set -- "${POSITIONAL[@]}"` 在空数组 + `set -u` 下中止
   （bash < 4.4）。任何无参调用都崩。
3. **`register-existing.sh`** —— `mapfile` 是 bash 4 builtin，macOS 上不存在，
   于是变量未设置、`set -u` 中止。
4. **`changelog-auto.sh`** —— 同样的 `mapfile`，外加 GNU-only 的 `tac` 与 `declare -A`。
5. **`scaffold-dashboard.sh`** —— 裸 `$1` 在 `set -u` 下无参崩溃；而显式路径**完全没有
   校验**：指向任意空目录就会把 `.dashboard/` 和 `scripts/` 撒进去。
6. **`dashboard.bats` —— CI hang 的根因**。`cd DIR && node parser.js &` 让 `$!` 拿到
   **子 shell** 的 PID，`kill` 从未碰到 node。13 个孤儿 server 持有 bats 继承的 fd，
   bats 就一直等下去 —— job 死在 15 分钟超时，**而那时每个测试都已经通过了**。

### 接手后

| 维度 | Before | After |
|------|--------|-------|
| 本地套件 | 85/108 + 无限挂起 | **108/108，75 秒，无孤儿进程** |
| CI 矩阵 | 只有 Linux | 新增 `bash32-compat`（macos-latest），既 parse 又 smoke-run（`test.yml` L38–62） |
| 语法检查 | 无 | 两个 bash 版本上全量 `bash -n` sweep |
| 孤儿进程 | 静默烧掉 job 超时 | 后置断言，回归就大声失败（`test.yml` L76–87） |

### 诚实备注

#13 里报的第 7 个问题 ——「cross-version 在失败时返回 exit 0」—— 是**误诊**。
那个脚本一直正确传播失败；它的 4 个失败是 bug 1 的下游，sync-project 修好后自动消失。
`f92fd53` 的 commit 正文自己写明了这一点。所以这个案例是 6 个 bug，不是 7 个。

### 核心教训

**绿色的 CI 只证明「CI 配置里写了的那些环境」是绿的。**

macOS 把 bash 3.2.57 装成 `/bin/bash`，那是 harness 的 macOS 用户实际执行的解释器。
它不在矩阵里，于是 CI 一直在提供**自信**而不是**证据** —— 而这一类失败只有真的 3.x
解析器能看见。

第二条教训：**`bash -n` 不够**。`mapfile` / `declare -A` 只在**运行**时失败，
语法检查全都通过。所以新的 `bash32-compat` job 既 parse 也 smoke-run。

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
