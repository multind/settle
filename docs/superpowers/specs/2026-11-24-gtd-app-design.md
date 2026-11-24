# GTD 个人生产力应用设计规格（AI 深度结合）

- **日期**：2026-11-24
- **状态**：已确认（用户逐节批准），待进入实现计划
- **版本**：1.0

---

## 1. 目标（Goal）

构建一个本地优先、AI 深度结合的 GTD（Getting Things Done）个人生产力应用。应用覆盖 GTD 五个环节——收集、理清、组织、回顾、执行——并在每一环提供 AI 辅助：AI 解析收件箱、智能理清、智能组织、智能回顾与"现在最该做什么"的执行建议。AI 永远只给建议，确认权始终在用户手中。应用以 Flutter 单代码库同时支持手机与桌面，响应式适配两套布局；数据以本地 Drift/SQLite 为主库、离线优先，在里程碑 3 引入 Supabase 账户与云同步；AI 模型支持 DeepSeek / OpenAI / Claude / Ollama 多模型切换，采用 BYOK 客户端直连与服务端代理双模式。当前为自己使用开发，架构按将来可能公开发布为多用户应用做准备。

---

## 2. 非目标（Non-Goals，YAGNI）

以下内容**明确不在本规格范围内**，任何里程碑都不实现：

- **多人协作 / 团队共享**：不做共享项目、成员协作、评论、任务分配。架构仅预留多用户数据维度，不做任何协作功能。
- **复杂报表与分析**：不做 BI 仪表盘、图表报表、生产力统计曲线。回顾环节仅保留基础计数统计（完成/新增/搁置）与 AI 周报文本。
- **系统日历集成**：不做桌面/手机原生日历的双向同步、iCal 导入导出。
- **系统级通知推送**：不做本地通知/推送提醒（提醒依赖用户在应用内查看）。
- **Web 端**：仅手机 + 桌面（Windows/macOS/Linux 桌面均由 Flutter 桌面构建覆盖），不做浏览器版本。
- **AI 训练 / 微调**：不做模型微调、个性化训练、RAG 知识库。
- **插件 / 扩展市场**：不做第三方插件系统、浏览器扩展、外部 API 开放平台。
- **端到端加密同步**：同步使用 HTTPS + Supabase 标准安全基线，不做 E2E 加密、密钥托管等复杂安全方案。
- **财务 / 计费**：不做订阅计费、应用内购买、账号等级体系。
- **其他收集渠道**：收集方式仅限规格列出的 输入 / 语音 / 分享 / 图片 四种，不扩展邮件转发、剪贴板监视、浏览器书签等新渠道。
- **游戏化与主题市场**：不做积分、成就系统、社区主题商店。

---

## 3. 背景与现状（Context）

- 项目目录 `D:\Project\gtd-project` 为全新仓库：仅 `git init` 一次、无任何提交，含一个已写好的 `.gitignore`（已包含 Flutter/Dart 构建产物、编辑器、`.env`、`*.key` 密钥类忽略规则）。**无既有代码可参考**，本规格即首个设计文档。
- 技术选型已确认：Flutter（Dart 3）多端单代码库；Drift/SQLite 本地主库；Supabase（里程碑 3）；AI 侧 BYOK 直连各模型官方 API 或 Ollama 本地接口，里程碑 3 增加 Supabase 服务端代理。
- 使用对象：当前个人自用；架构决策（分层、数据封装、无全局单例）为将来公开发布、多账户留出扩展缝。
- 使用语言：中英双语，应用语言默认跟随系统，设置页可手动切换。
- 开发环境：Windows（仓库 `.gitignore` 已含 windows/flutter ephemeral 规则），桌面端首先面向 Windows 验证，其余桌面平台由 Flutter 保证。

---

## 4. 总体架构（三层解耦）

### 4.1 三层划分

```
┌─────────────────────────────────────────────────────────────┐
│  界面层（Flutter，响应式两套布局：手机底部导航 / 桌面侧边栏）    │
│  只做展示与交互，调用下层用例；不直接触碰数据库与模型客户端      │
├─────────────────────────────────────────────────────────────┤
│  ① GTD 核心层（领域层）                                        │
│  数据模型 + 业务流程（收集→理清→组织→回顾→执行）                │
│  完全不依赖 AI：无 AI 配置、断网、AI 全挂时应用完整可用          │
├─────────────────────────────────────────────────────────────┤
│  ② AI 引擎层                                                  │
│  模型抽象（统一 AIClient）+ 五种 AI 能力 + Prompt/JSON Schema  │
│  BYOK 客户端直连 / 服务端走 Supabase 代理（里程碑 3）           │
│  只输出建议，永不改写数据                                     │
├─────────────────────────────────────────────────────────────┤
│  ③ 同步与云端层（里程碑 3）                                    │
│  本地 Drift/SQLite 为主库；Supabase 账户 + 离线优先同步引擎     │
│  + 服务端 AI 代理；云端未部署不影响本地使用                     │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 依赖方向与不变量

- 依赖只允许 **界面 → GTD 核心** 与 **界面 → AI 引擎**；**AI 引擎 → GTD 核心（只读领域数据）**；**GTD 核心 → 数据层**。AI 引擎绝不反向依赖界面，同步层只与数据层交互。
- 不变量 1：**AI 挂不影响 GTD 核心**。GTD 核心层编译与运行时不包含任何 AI 依赖，AI 引擎通过接口注入，缺失时界面隐藏 AI 入口。
- 不变量 2：**云端未部署不影响本地使用**。同步层在里程碑 3 以可选模块接入，未配置账户时本地照常工作。
- 每层独立开发与独立测试（见 §11 测试策略），层间以明确接口通信，禁止跨层调用。

### 4.3 技术栈汇总

| 关注点 | 选型 | 说明 |
|--------|------|------|
| UI | Flutter（单代码库） | 手机 + 桌面响应式，`LayoutBuilder` 按断点切换两套导航布局 |
| 本地库 | Drift + SQLite | 主库，离线优先；迁移版本化 |
| 状态管理 | Riverpod | 数据层 Repository 经 Provider 注入，杜绝全局单例（为多账户留缝） |
| 云同步 | Supabase（M3） | 账户、Auth、行级数据同步、Edge Functions 承载服务端 AI 代理 |
| AI 客户端 | 统一 AIClient | DeepSeek / OpenAI / Claude（OpenAI 兼容 / 原生协议）+ Ollama 本地 HTTP |
| 密钥存储 | flutter_secure_storage | BYOK Key 加密存储，不落数据库明文 |
| i18n | flutter_localizations + ARB | 中英双语，默认跟随系统 |

---

## 5. 数据模型（6 核心实体 + 1 个 M2 实体）

本地主库表定义（Drift）。时间字段统一为 **INTEGER，Unix 纪元毫秒**；枚举字段统一为 **TEXT 存储枚举名**（可读、便于迁移）。

### 5.1 表定义

**`inbox_items` 收件箱条目（独立实体，收集的第一落点）**

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK，自增 | |
| raw_text | TEXT | NOT NULL | 原始材料原文，始终保留 |
| source | TEXT | NOT NULL | `text` / `voice` / `share` / `image`（语音/分享/图片仅 M3 产生，字段 M1 即建好） |
| ai_hint | TEXT | NULL | AI 收集解析建议，JSON 文本（schema 见 §6.4）；NULL 表示尚无建议 |
| prompt_version | TEXT | NULL | 产生该建议的 Prompt 版本号（可追溯） |
| status | TEXT | NOT NULL | `pending`（待理清）/ `clarified`（已理清） |
| created_at | INTEGER | NOT NULL | |
| updated_at | INTEGER | NOT NULL | |

**`tasks` 行动/任务**

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK，自增 | |
| title | TEXT | NOT NULL | 动词开头的行动描述 |
| notes | TEXT | NULL | 备注/补充信息 |
| status | TEXT | NOT NULL | `next_action`（下一步）/ `waiting`（等待）/ `someday`（将来也许）/ `done`（完成） |
| due_date | INTEGER | NULL | 截止日（毫秒时间戳） |
| scheduled | INTEGER | NULL | 计划执行时间 |
| energy | TEXT | NULL | `low` / `medium` / `high` |
| priority | TEXT | NULL | `low` / `medium` / `high` |
| waiting_on | TEXT | NULL | 仅 `status = waiting` 时填写：在等谁/等什么 |
| project_id | INTEGER | NULL，FK → projects.id | |
| context_id | INTEGER | NULL，FK → contexts.id | |
| created_at | INTEGER | NOT NULL | |
| updated_at | INTEGER | NOT NULL | |

索引：`project_id`、`context_id`、`status`、`due_date`。

**`projects` 项目**

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK，自增 | |
| name | TEXT | NOT NULL | |
| goal | TEXT | NULL | 项目目标/期望结果 |
| status | TEXT | NOT NULL | `active`（进行中）/ `done`（完成）/ `someday`（将来） |
| created_at / updated_at | INTEGER | NOT NULL | |

与 Task 为 **1:N**（一个项目含多个 Task）。

**`contexts` 情境**

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK，自增 | |
| name | TEXT | NOT NULL | 如 `@电脑` / `@外出` / `@电话` |
| icon | TEXT | NULL | 图标标识（Material icon 名） |
| sort | INTEGER | NOT NULL | 展示排序，默认 0 |

首次启动种子数据：`@电脑`、`@外出`、`@电话` 三个默认情境。Task 与 Context 为 **N:1**。

**`tags` 标签** 与 **`task_tags` 关联表（Task N:N Tag）**

| tags 字段 | 类型 | 约束 |
|------|------|------|
| id | INTEGER | PK，自增 |
| name | TEXT | NOT NULL，UNIQUE |
| color | TEXT | NOT NULL（十六进制色值，如 `#1A73E8`） |

| task_tags 字段 | 类型 | 约束 |
|------|------|------|
| task_id | INTEGER | PK 组成，FK → tasks.id |
| tag_id | INTEGER | PK 组成，FK → tags.id |

**`reviews` 回顾**

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK，自增 | |
| date | INTEGER | NOT NULL | 回顾日期（当日起始毫秒时间戳），每周一条 |
| summary | TEXT | NULL | 手动回顾总结 |
| stats | TEXT | NULL | 统计 JSON：`{"done": n, "new": n, "stalled": n}` |
| ai_report | TEXT | NULL | AI 周报 JSON（schema 见 §6.4） |
| created_at | INTEGER | NOT NULL | |

**`references` 参考资料（里程碑 2 引入，加入核心层）**

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INTEGER | PK，自增 | |
| title | TEXT | NOT NULL | |
| content | TEXT | NULL | 资料内容 |
| tags | TEXT | NULL | 标签名逗号分隔 |
| created_at / updated_at | INTEGER | NOT NULL | |

### 5.2 任务状态流转（理清流程）

```
收集：任意界面快速输入 → InboxItem(raw_text, source, status=pending)
        │
理清：InboxItem(status → clarified)
        ├─→ Task(status = next_action)          # 单步可执行
        ├─→ Task(status = waiting) + waiting_on # 在等某人/某事
        ├─→ Task(status = someday)              # 将来也许
        ├─→ Project(active)                     # 多步骤目标 → 继续拆出 Task
        ├─→ Reference(M2 起)                    # 参考资料
        └─→ 删除（二次确认，硬删除）
```

状态间迁移规则：

- `next_action ↔ waiting`：可互转，转 `waiting` 时必须填写 `waiting_on`。
- `next_action / waiting / someday → done`：完成即状态置 `done`（不删除记录）。
- `done → next_action`：允许重新打开。
- 删除一律为**硬删除 + 二次确认**；删除 Project 时其下 Task 一并删除（二次确认），删除 Context 时关联 Task 的 `context_id` 置空。
- Tag 无状态，删除后从所有 Task 解绑。

### 5.3 已确认的设计取舍

1. **收件箱是独立实体**而非 Task 的一种状态：保留原始材料原文、来源与 AI 解析留痕，理清后可追溯。
2. **等待是 Task 状态 + `waiting_on` 字段**而非独立实体：避免实体爆炸，等待视图只是 `tasks.status = waiting` 的过滤视图。
3. **Reference 是核心层实体**（不属于 AI 层）：理清的目标之一是转参考，M2 引入时加入核心层，AI 仅在理清时建议"转为参考"。

---

## 6. AI 引擎

### 6.1 核心原则（确认即写入）

- **AI 永远只给建议，确认权在用户**。AI 永不直接写库。
- 数据流固定为：`原始数据 → AI 建议（JSON）→ 用户确认/修改 → 写入数据库`。
- 每条建议必须携带 **`why`（为什么这么建议）**、**`confidence`（置信度）**、**`prompt_version`（Prompt 版本）**、**`model`（模型标识）**。
- 界面提供**一键采纳**或**逐字段修改**两种落库方式；建议可稍后处理，不做强制弹窗。

### 6.2 五种 AI 能力（各自独立、可单独裁剪）

| 能力 | 输入 | 输出建议对象 | 用户确认后的落库动作 |
|------|------|--------------|---------------------|
| ① 收集解析 `parse_inbox` | InboxItem.raw_text | 标题 / 截止日 / 项目线索 / 情境 / 标签 | 写入 `ai_hint` + `prompt_version`（**不落 Task**，待理清时引用） |
| ② 智能理清 `clarify` | 一条 InboxItem + 可选现有项目列表 | 判定类型（行动/项目/参考/删除）；若为行动：动词开头下一步、多步拆分、建议状态/优先级/精力/截止日 | 创建 Task（或拆成多条 Task / 新建 Project / 新建 Reference / 提示删除） |
| ③ 智能组织 `organize` | 多条 Task（用户选中批量）或单条 Task + 现有项目/情境/标签列表 | 匹配已有项目或建议新建、建议情境与标签、批量统一归类 | 批量写入 project_id / context_id / tag 绑定 |
| ④ 智能回顾 `weekly_review` | 回顾周期内的统计 + 任务/项目数据 | 完成/新增/搁置统计、卡住项目识别、下周建议、周报总结 | 落 `reviews.stats` + `reviews.ai_report` |
| ⑤ 执行建议 `recommend_now` | 当前情境/精力 + 未完成任务（按优先级/截止日/已排期） | "现在最该做的事" Top 建议 + 理由，可附番茄钟时长估算 | **不落库**，纯展示；用户决定后自行开始任务 |

### 6.3 模型抽象层：统一 AIClient 接口

```dart
/// 统一模型客户端接口。BYOK 直连（DirectClient）与服务端代理（ProxyClient）共用。
abstract class AIClient {
  String get id;        // 'deepseek' | 'openai' | 'claude' | 'ollama'
  String get mode;      // 'direct' | 'proxy'

  /// 非流式完成：返回结构化 JSON 文本，调用方按 schemaId 校验。
  Future<AIResponse> complete({
    required Prompt prompt,
    required String schemaId,
    double temperature = 0.3,
    int maxTokens = 2000,
  });

  /// 流式完成：用于长输出（周报、批量理清），逐块返回增量文本。
  Stream<AIChunk> completeStream({
    required Prompt prompt,
    required String schemaId,
  });

  /// 校验 Key 有效性与连通性（返回有效/无效/网络不可达）。
  Future<KeyStatus> validateKey();
}

/// Prompt = 系统提示 + 用户提示 + promptVersion + schemaId。
/// promptVersion 全局递增，如 'clarify.v3'，用于建议溯源与回滚。
class Prompt {
  final String system;
  final String user;
  final String promptVersion;
  final String schemaId;
}
```

- **DirectClient（M2）**：BYOK 直连。DeepSeek / OpenAI / Claude 走各自官方 HTTP API（OpenAI 兼容协议统一封装，Claude 走 Anthropic 原生协议适配层），Ollama 走本地 HTTP（无 Key，需配置 base URL）。Key 经 `flutter_secure_storage` 加密存储。
- **ProxyClient（M3）**：客户端不带 Key，请求发送到 Supabase Edge Function，由服务端持有密钥并转发模型。
- 一个 Provider（Riverpod）按设置动态选择当前生效的 AIClient；配置为"无模型"时，五个能力入口全部隐藏，应用回退纯手动模式。

### 6.4 JSON Schema 约束输出 与 Prompt 版本化

**输出约束**：每个能力对应一个 JSON Schema（`assets/schemas/<schemaId>.json`），客户端对返回文本做 Schema 校验；校验失败→携带校验错误**重试 1 次**→仍失败则**该次建议降级为"无建议"**并提示手动处理。

**Prompt 注册表**（版本号随模板修改递增，建议内容记录版本可溯源、可回滚）：

| 能力 | schemaId | 初始版本 |
|------|----------|----------|
| 收集解析 | `parse_inbox.v1` | `parse_inbox.v1` |
| 智能理清 | `clarify.v1` | `clarify.v1` |
| 智能组织 | `organize.v1` | `organize.v1` |
| 智能回顾 | `weekly_review.v1` | `weekly_review.v1` |
| 执行建议 | `recommend_now.v1` | `recommend_now.v1` |

**`ai_hint` 示例（收集解析建议，存 InboxItem.ai_hint）**：

```json
{
  "schema": "parse_inbox.v1",
  "prompt_version": "parse_inbox.v1",
  "model": "deepseek",
  "title": "给客户发季度报告",
  "due_date": "2026-11-30",
  "project_hint": "客户交付",
  "context_hint": "@电脑",
  "tag_hints": ["报告", "客户"],
  "confidence": 0.9,
  "why": "原文提到'下周一前发给客户'，推断截止日为 2026-11-30"
}
```

**理清建议示例（智能理清输出）**：

```json
{
  "schema": "clarify.v1",
  "prompt_version": "clarify.v1",
  "model": "deepseek",
  "kind": "action",
  "suggested_task": {
    "title": "撰写季度报告初稿",
    "status": "next_action",
    "priority": "high",
    "energy": "medium",
    "due_date": "2026-11-30",
    "project_hint": "客户交付",
    "context_hint": "@电脑"
  },
  "split_into": ["整理数据", "撰写初稿", "发给客户校对"],
  "confidence": 0.85,
  "why": "原文含多步操作且有明确截止日，适合拆分为 3 个行动并归入'客户交付'项目"
}
```

**周报示例（智能回顾落 reviews.ai_report）**：

```json
{
  "schema": "weekly_review.v1",
  "prompt_version": "weekly_review.v1",
  "model": "deepseek",
  "stats": { "done": 12, "new": 8, "stalled": 2 },
  "stuck_projects": ["客户交付"],
  "next_week_suggestions": ["清理收件箱 5 条待理清", "跟进等待中的报销"],
  "summary": "本周完成情况良好，下周聚焦客户交付项目并清理积压收件箱。",
  "confidence": 0.8,
  "why": "基于本周实际完成/新增/搁置计数与各项目最近活动时间得出"
}
```

**执行建议示例（recommend_now 输出，不落库）**：

```json
{
  "schema": "recommend_now.v1",
  "prompt_version": "recommend_now.v1",
  "model": "deepseek",
  "task_id": 42,
  "title": "撰写季度报告初稿",
  "why": "截止日 11-30 临近，精力中等，当前 @电脑 情境匹配",
  "pomodoro_estimate": 3,
  "confidence": 0.87
}
```

### 6.5 流式、重试、超时与离线降级

- **流式**：仅长输出（周报、批量理清）使用 `completeStream`；短建议（解析、执行建议）用非流式 `complete`，降低复杂度。
- **重试与超时**：网络/5xx 类错误按指数退避重试（1s / 2s / 4s，最多 3 次）；单次请求超时默认 30s（Ollama 本地可放宽到 60s）。
- **连续失败降级**：同一能力在一次会话内连续失败 ≥3 次 → 标记该能力 `degraded`，界面降级为手动模式并显示"重试"入口。
- **Key 无效**：`validateKey()` 检测 401/403 → 设置页引导重新配置 Key，不反复轰炸请求。
- **离线**：网络不可达时 AI 入口隐藏/禁用（不假死、不排队 AI 请求），GTD 核心功能完整可用；M3 起待同步变更入队，联网自动推送。

---

## 7. 界面与交互

### 7.1 响应式两套布局（单代码库）

- **手机端（窄屏）**：底部导航五项——收件箱 / 今日 / 项目 / 回顾 / 设置。收件箱页**顶部常驻快速收集框**（支持语音按钮，语音 M3 启用）。
- **桌面端（宽屏）**：左侧边栏导航——收件箱 / 今日 / 项目 / 情境 / 等待 / 回顾 / 设置。今日页含 AI 建议卡片。
- 断点切换：以 `LayoutBuilder` 宽度阈值（如 600px）切换布局，同一套页面组件复用。

### 7.2 关键界面

| 界面 | 内容 |
|------|------|
| 收件箱 | 条目列表（原文、来源徽标、状态）+ 每条 AI 解析状态徽标（未解析 / 有建议 / 已采纳）+ 快速收集框 + 语音按钮（M3） |
| 今日 | 今日行动列表（按截止日/优先级/排期）+ **AI 执行建议卡片**（"现在最该做的事" + 理由 + 番茄钟估算 + **换一个**按钮刷新） |
| 理清向导 | 卡片式向导：AI 建议（含 why/confidence）→ 用户确认或逐字段修改 → 落库（Task/Project/Reference/删除四选一） |
| 项目 / 情境 / 等待 / 将来也许 | 对应过滤视图；等待视图展示 `status = waiting` 的 Task 及 `waiting_on`；项目视图展示项目卡片与其下 Task |
| 回顾 | 每周回顾：手动填写总结 + 统计展示 + **AI 周报卡片**（可一键采纳写入 Review） |
| 设置 | 语言切换、AI 模型配置（Provider/Key/Base URL/模型名）、BYOK 与代理模式切换、导出备份、账户（M3） |

### 7.3 交互原则（已确认）

1. **收集零门槛**：任意界面 1–2 步内可发起收集（全局快捷键/浮动入口），收集只要求"写一句话"，其余字段理清时再补。
2. **AI 建议不打断**：以**徽标 / 卡片**形式呈现，用户可稍后处理或忽略，**不强制弹窗**。
3. **确认权在用户**：所有 AI 输出进入"确认/修改"路径后才写库，界面无任何"AI 直接生效"操作。

### 7.4 视觉设计规范（质感拟物 + 双主题）

#### 7.4.1 总体风格

- 视觉方向为 **Material 3 基础上的「质感拟物」**（用户已确认预览稿 `preview-ui-v3.html`「质感拟物 v3 强化版」为正式规范）；本节所有色值、透明度、模糊值均取自该稿，作为 Task 33（`lib/app/theme.dart`）实现的唯一数值来源。
- 四大视觉特征：
  - **彩色光斑背景**：4 个径向渐变彩色光斑（红 / 紫 / 青 / 黄）叠加一层线性渐变底色；
  - **强对比渐变**：按钮、激活项、徽标、复选框大面积使用双色 `135deg` 渐变；
  - **彩色投影**：阴影带蓝色 / 紫色光晕（如 `0 18px 50px rgba(36,86,255,.28)`），浅深两套均有；
  - **高饱和毛玻璃**：`backdrop-filter: blur(24–28px) saturate(180%)` 用于导航条、侧边栏、容器、卡片，卡片同时使用半透明底色。
- **双主题**：浅色 / 深色两套完整 token，跟随系统自动切换（`ThemeMode.system`）；预览稿中的「🌙 / ☀️ 切换主题」按钮仅作设计预览对比，**不作为产品功能**（本规格无应用内手动主题切换）。

#### 7.4.2 双主题设计 Token

下表取值取自 `preview-ui-v3.html` 的 `:root`（浅色）与 `body.dark`（深色）CSS 变量；渐变类 token 以「端点色值对」给出，具体应用方向见 §7.4.3 组件规则。

| Token | 浅色（light） | 深色（dark） | 说明 |
|------|--------------|--------------|------|
| 主色 primary 渐变端点 | `#2456FF` / `#00C2FF` | `#4D7DFF` / `#00D4FF` | 侧边栏激活项、导航激活点；应用方向 primary→primary2 |
| 辅助色 accent 渐变端点 | `#00B478` / `#00E676` | `#00E676` / `#00C4FF` | 快速收集框、复选框选中、主按钮；应用方向 accent2→accent |
| AI 色 ai 渐变端点 | `#7C3DFF` / `#D400FF` | `#B388FF` / `#FF66E5` | AI 徽标、AI 卡片；应用方向 ai2→ai |
| 文字色 text | `#141B33` | `#EEF1FF` | 主文字 |
| 次要文字 muted | `#5A6285` | `#8F97C0` | 次要文字、未激活图标 |
| 卡片底色 card | `rgba(255,255,255,.60)` | `rgba(28,34,64,.55)` | 容器 / 卡片半透明底（配合毛玻璃） |
| 卡片实底 card-solid | `rgba(255,255,255,.92)` | `rgba(30,38,72,.9)` | 任务卡片 / 列表行实底 |
| 边框高光 stroke | `rgba(255,255,255,.9)` | `rgba(255,255,255,.22)` | 卡片描边、分隔线（浅色下呈高光感） |
| 导航条底 nav | `rgba(255,255,255,.45)` | `rgba(16,22,46,.5)` | 手机底部导航 |
| 侧边栏底 sidebar | `rgba(255,255,255,.40)` | `rgba(16,22,46,.45)` | 桌面侧边栏 |
| 输入框底 field | `rgba(255,255,255,.55)` | `rgba(255,255,255,.08)` | 输入类控件底 |
| 建议徽标底 chip / 字 chip-text | `rgba(0,180,120,.16)` / `#00775A` | `rgba(0,230,118,.2)` / `#6DF7B3` | 建议徽标（accent 浅底深字） |
| 大投影 shadow | `0 18px 50px rgba(36,86,255,.28), 0 4px 12px rgba(20,27,51,.12)` | `0 20px 60px rgba(0,0,0,.6), 0 4px 16px rgba(0,0,0,.4)` | 容器、桌面壳、手机壳 |
| 小投影 shadow-sm | `0 8px 22px rgba(36,86,255,.18)` | `0 10px 28px rgba(0,0,0,.45)` | 卡片、列表行 |
| 底色渐变 bg1 / bg2 | `#DDE7FF` / `#FFE9D6` | `#0A0E22` / `#1C0F2E` | 光斑背景最底层 `linear-gradient(160deg)` |

#### 7.4.3 组件样式规则

**背景（结构两主题通用，底色两套）**

- 底层：`linear-gradient(160deg, bg1, bg2)` 固定铺满（浅 `#DDE7FF→#FFE9D6`；深 `#0A0E22→#1C0F2E`）。
- 叠加 4 个径向渐变彩色光斑（位置 / 尺寸按 preview 的比例参考，Flutter 端用视口相对坐标）：
  - 红：`radial-gradient(520px 380px at 12% 8%, rgba(255,94,58,.55), transparent 70%)`
  - 紫：`radial-gradient(600px 420px at 88% 12%, rgba(124,61,255,.5), transparent 70%)`
  - 青：`radial-gradient(640px 480px at 50% 95%, rgba(0,196,255,.45), transparent 70%)`
  - 黄：`radial-gradient(480px 360px at 82% 78%, rgba(255,214,0,.5), transparent 70%)`

**毛玻璃（backdrop-filter）**

- 容器（桌面壳 / 手机壳 / 区块容器）：`blur(28px) saturate(180%)`，底 `card`。
- 手机底部导航：`blur(24px) saturate(200%)`，底 `nav`，顶边 `stroke` 分隔。
- 桌面侧边栏：`blur(24px) saturate(180%)`，底 `sidebar`，右边 `stroke` 分隔。
- 任务卡片 / 列表行：`blur(10px)`，底 `card-solid`，描边 `stroke`，阴影 `shadow-sm`；完成项整卡 `opacity .55`。
- 页面主标题微光：`text-shadow: 0 2px 12px rgba(255,255,255,.4)`（preview 中浅深两套同值）。

**渐变按钮与高亮**

- **快速收集框**（手机收件箱顶部常驻）：`linear-gradient(135deg, accent2, accent)`（浅 `#00E676→#00B478`，深 `#00C4FF→#00E676`）+ 白色文字 + 光晕 `0 10px 26px rgba(0,180,120,.45)` + 高光描边 `1px rgba(255,255,255,.35)`，圆角 16px；语音按钮为框内白色半透明圆形（底 `rgba(255,255,255,.3)` + 内圈描边 `rgba(255,255,255,.4)`）。
- **侧边栏激活项**（桌面）：`linear-gradient(135deg, primary, primary2)`（浅 `#2456FF→#00C2FF`，深 `#4D7DFF→#00D4FF`）+ 白色文字 + 发光 `0 8px 20px rgba(36,86,255,.5)`，圆角 10px。
- **复选框**：18×18、圆角 6px；未选：`2px solid primary` + 微光 `0 0 10px rgba(36,86,255,.25)`；选中：`linear-gradient(135deg, accent2, accent)` + 白色勾号 + 光晕 `0 4px 12px rgba(0,180,120,.5)`。
- **品牌字**（桌面侧边栏顶部「GTD」）：`linear-gradient(135deg, primary, accent)` 渐变文字（前景渐变实现）。
- **导航激活点**（手机底部导航）：6×6 圆点，`linear-gradient(135deg, primary2, primary)` 底 + `0 0 8px primary` 发光。

**AI 卡片（今日页执行建议）**

- 底：`linear-gradient(135deg, rgba(124,61,255,.35), rgba(212,0,255,.25))`（ai 渐变半透明版，浅深两套同值）；文字白色，理由行 `rgba(255,255,255,.75)`。
- 投影：`0 12px 32px rgba(124,61,255,.4)`（紫色光晕），描边 `1px rgba(255,255,255,.45)`，`blur(8px)`，圆角 16px。
- 卡片内按钮：「开始」= accent 渐变 + 白字 + `0 6px 16px rgba(0,180,120,.5)`，圆角 10px；「换一个」= 底 `rgba(255,255,255,.25)` + 半透明白描边 + `blur(6px)`。

**徽标（圆角 8px）**

- **AI 徽标**（「AI 已解析」）：`linear-gradient(135deg, ai2, ai)`（浅 `#D400FF→#7C3DFF`，深 `#FF66E5→#B388FF`）+ 白字 + `0 3px 10px rgba(212,0,255,.35)`。
- **建议徽标**（前缀「建议：」，如「建议：行动 · 截止 12-02」）：accent 浅底深字——浅色底 `rgba(0,180,120,.16)` / 字 `#00775A`；深色底 `rgba(0,230,118,.2)` / 字 `#6DF7B3`。
- **待解析徽标**（「待 AI 解析」）：底 `rgba(139,147,181,.18)` + `muted` 字（浅深两套同值）。

**圆角体系**：容器 18px / 卡片、收集框 16px / 列表行 12px / 按钮 10px / 徽标 8px，Flutter 端统一为 token。

#### 7.4.4 Flutter 实现映射（Task 33 `lib/app/theme.dart` 方向）

Task 33（`lib/app/theme.dart` 的 `buildAppTheme()`）**不以 `ColorScheme.fromSeed` 为唯一手段**：按本节 token 用显式色值构建浅 / 深两套 `ThemeData`。

- **双主题构建**：token 常量集中定义（建议 `AppTokens.light` / `AppTokens.dark` 两个 const 集合）；`buildAppTheme(Brightness)` 用 token 手工构造 `ColorScheme`（primary / secondary 取渐变端点色，ai 色经 `ColorSchemeExtension` 挂扩展字段），`useMaterial3: true`；`app.dart` 中 `MaterialApp(theme: 浅色, darkTheme: 深色, themeMode: ThemeMode.system)`。
- **毛玻璃**：`BackdropFilter` + `ImageFilter.blur` + 半透明色底。CSS `blur(N px)` ≈ Flutter `sigma = N/2`（28px→σ14、24px→σ12、16px→σ8、10px→σ5、8px→σ4）；`saturate(180%)` 用 `ColorFiltered`（`ColorFilter.matrix` 饱和度矩阵 1.8）包裹。
- **渐变**：组件双色渐变用 `LinearGradient(begin: topLeft, end: bottomRight)`（对应 CSS `135deg`）；光斑背景用 `RadialGradient`（center / radius 按视口相对坐标）。
- **彩色阴影**：`BoxShadow(color: 带透明度)`——透明度换算规则 `α → round(α×255)` 作色值前两位，如 `rgba(36,86,255,.28)` ≈ `Color(0x472456FF)`；多层阴影用 `List<BoxShadow>`。
- **光斑背景**：`Stack` 叠加 4 个 `Container(decoration: BoxDecoration(gradient: RadialGradient(...)))` + 最底层 `LinearGradient(160deg, bg1, bg2)` 的 `DecoratedBox`；封装为 `lib/app/` 下的背景组件，供手机 / 桌面两套布局复用。
- **组件主题挂接**：容器 / 导航 / 卡片 / 输入框统一走 `ThemeData` 组件主题（`CardTheme`、`NavigationBarTheme`、`NavigationRailTheme`、`InputDecorationTheme`、`AppBarTheme`），界面代码不散写色值。
- **AI 元素样式先定义**：ai 渐变端点、AI 卡片阴影、徽标底等 token 在 M1 即进 `theme.dart`，M2 / M3 启用功能时直接引用，不做二次取色。

#### 7.4.5 落地范围（M1 / M2）

- **M1 即生效**：页面骨架、双主题配色 token、毛玻璃（导航条 / 侧边栏 / 容器 / 卡片）、渐变按钮与激活态、彩色阴影、圆角体系、光斑背景；`theme.dart` 输出浅 / 深两套 `ThemeData`，`app.dart` 挂 `themeMode: ThemeMode.system`。M1 界面不渲染 AI 元素（AI 徽标、AI 卡片），快速收集框不带语音按钮——与 §8.1「AI 模型配置为占位入口」一致。
- **M2 启用**：AI 建议卡片、AI 徽标（「AI 已解析」「建议：行动 · 截止 12-02」）随 §8.2 启用，直接使用 M1 已定义的样式。
- **M3 启用**：语音按钮（快速收集框内）按 §8.3 启用，样式沿用 §7.4.3 已定义的语音按钮样式。
- AI / 语音元素相关样式（ai 渐变、AI 卡片阴影、语音按钮圆形样式）**于 M1 即定义进主题 token**，仅功能启用时间不同。

---

## 8. 里程碑划分与验收标准（方案 C 分层渐进）

每个里程碑都是**可独立交付的完整版本**，按"数据层 → 功能 → 界面 → 验收"小步推进。

### 8.1 里程碑 1 — GTD 核心地基（无 AI）

范围：Flutter 脚手架（手机 + 桌面）→ Drift 本地库（6 实体 + 关联表）→ 收件箱快速输入 → 手动理清流程 → 项目 / 情境 / 等待 / 将来也许视图 → 手动回顾 → 设置页（语言切换、JSON 导出备份；AI 模型配置为占位入口，M2 填充）→ i18n 骨架（核心导航与常用文案双语）。

验收清单（全部通过即里程碑完成）：

- [ ] 同一代码库启动手机与桌面两端，断点切换两套布局正确
- [ ] 任意界面 1–2 步内可快速收集，收件箱列表显示原文、来源、状态
- [ ] 手动理清：每条收件箱可转为 Task（下一步/等待/将来也许）、Project 或删除，流转规则符合 §5.2
- [ ] Task 可设置截止日、计划时间、精力、优先级、等待对象、所属项目、情境、标签
- [ ] 项目 / 情境 / 等待 / 将来也许 四个视图分组展示正确
- [ ] 手动回顾：填写总结与统计并保存
- [ ] 设置页：语言切换可用；全库 JSON 导出/恢复可用
- [ ] 中英双语骨架可切换
- [ ] 纯本地运行，断网环境走查无异常
- [ ] 数据层与界面层测试通过（§11）

### 8.2 里程碑 2 — AI 引擎（BYOK 直连）

范围：模型抽象层（AIClient + DirectClient：DeepSeek/OpenAI/Claude/Ollama）→ 五种 AI 能力 → Prompt 版本化 + JSON Schema 校验 → 确认式交互界面 → 离线降级。

验收清单：

- [ ] 五种能力均可调用；DeepSeek / OpenAI / Claude / Ollama 各至少验证一种可用场景
- [ ] 收集解析：输入原文 → 徽标提示有建议 → 展开显示建议 + why + confidence → 一键采纳或逐字段修改 → 落 `ai_hint`；理清时可引用该建议
- [ ] 智能理清：判定行动/项目/参考/删除；行动生成动词开头下一步；多步拆分；建议状态/优先级/精力/截止日；确认后正确落库
- [ ] 智能组织：匹配已有项目或建议新建、建议情境标签、批量统一归类可确认执行
- [ ] 智能回顾：生成周报（统计 + 卡住项目 + 下周建议），确认后落 `reviews.ai_report`
- [ ] 执行建议：今日卡片给出"现在最该做的事" + 理由，可"换一个"，不落库
- [ ] Reference 实体（M2 引入）随理清流程可用
- [ ] 断网时 AI 入口隐藏/禁用，GTD 功能完整可用
- [ ] 建议记录携带 `prompt_version` 与 `model` 可追溯
- [ ] JSON Schema 校验失败 → 重试 1 次 → 降级"无建议"路径可走通
- [ ] AI 层测试通过（§11）

### 8.3 里程碑 3 — 云端与发布

范围：Supabase + 账户体系 → 同步引擎（离线优先 + 冲突处理）→ 语音 / 分享 / 图片收集 → 服务端 AI 代理 → 全量双语。

验收清单：

- [ ] 账户注册/登录；同一账户多设备登录
- [ ] 离线修改 → 联网自动同步，多设备数据最终一致
- [ ] 冲突场景（同字段双方修改）走字段级合并或手动选择，路径可用（§9）
- [ ] 手机端语音收集可用；系统分享菜单转发可用；图片文字识别（OCR）收集可用
- [ ] 服务端 AI 代理可用（客户端不携带 Key 的发布配置）
- [ ] 全量中英双语
- [ ] 可对外发布（安全基线复核：无明文密钥、无硬编码账户依赖）

---

## 9. 错误处理与数据安全

### 9.1 错误处理矩阵

| 场景 | 行为 |
|------|------|
| 离线（网络不可达） | 本地照常；AI 入口隐藏/禁用；M3 起变更写入同步队列，联网自动推送 |
| AI 请求失败 | 指数退避重试（1s/2s/4s，最多 3 次）；连续失败 ≥3 次该能力降级手动 + 提供重试入口 |
| Key 无效 / 401 | `validateKey()` 检测后设置页引导重新配置，不反复请求 |
| 输出不符合 Schema | 携带校验错误重试 1 次；仍失败 → 该次建议降级"无建议"，提示手动处理 |
| 同步冲突（M3） | 字段级合并：非冲突字段各自保留；同字段冲突按 `updated_at` **最后写入优先**；关键冲突（删除 vs 修改、整条被双方改写）→ 弹窗用户手动选择（保留本地 / 采用远端 / 合并） |
| 数据库损坏 | 导出备份可用于恢复；数据库打开失败时提示并提供备份恢复入口 |

### 9.2 数据安全

- **导出备份**：设置页一键导出全库为 JSON（覆盖 6+1 实体），用于备份与迁移。
- **BYOK Key 加密存储**：`flutter_secure_storage`（平台级安全存储），不写数据库、不写日志；`.env` 与 `*.key` 已被 `.gitignore` 忽略。
- **数据库迁移版本化**：Drift `schemaVersion` 递增 + 迁移步骤文件（`lib/data/migrations/`）；任何表结构变更必须走迁移，禁止删库重建。
- **服务端密钥（M3）**：Supabase Edge Function 环境变量持有，客户端不可见。

---

## 10. 将来发布考虑

- **多用户准备**：M1/M2 数据访问一律经 Repository + Riverpod Provider 注入，**不使用全局单例**；M3 引入账户作用域时，Repository 加一层账户过滤即可，不需要重构领域层。数据表不硬编码单用户假设（无全局常量用户 ID）。
- **安全基线**：任何对外发布前复核——密钥不进客户端（BYOK 模式仅个人使用，发布默认走服务端代理）、日志不含敏感数据、备份/同步传输走 HTTPS。
- **发布范围**：本规格不包含商店上架流程、签名、崩溃上报等运营设施；这些在 M3 完成后另行评估。
- **私有构建**：当前个人使用可保持 BYOK 直连、不部署云端；本地数据与 GTD 功能（M1/M2 全部）不受影响；M3 中依赖云端的能力（账户、跨设备同步、服务端 AI 代理）在此模式下不启用，语音/分享/图片收集本身仍可用。

---

## 11. 测试策略（四层）

| 层 | 手段 | 覆盖内容 |
|----|------|----------|
| 数据层 | Drift 单元测试（内存数据库） | 各实体 CRUD；状态流转（pending→clarified→Task；next_action↔waiting 带 waiting_on 约束；→done；删除级联）；索引与唯一约束；迁移测试 |
| AI 层 | Schema 校验测试 + 固定 JSON mock 模型（FakeAIClient） | 每个能力对固定样例 JSON 的解析与 Schema 校验通过/失败路径；校验失败重试与降级逻辑；离线降级（FakeAIClient 抛网络错误 → 能力返回"无建议"）；Prompt 版本号随建议正确记录 |
| 界面层 | Widget 测试 | 收件箱列表与快速收集框；理清向导（确认/修改/取消三条路径）；AI 建议卡片（采纳/换一个/忽略）；离线时 AI 入口隐藏 |
| 验收走查 | 每里程碑结束手动走查 | 按 §8 验收清单人工执行完整 GTD 五步流程（含断网场景） |

测试目录规划：`test/data/`、`test/ai/`、`test/widget/`、`test/acceptance/`（走查清单文档）。

---

## 12. 文件清单（Files To Change）

仓库为全新项目，以下为计划创建的目录/文件结构（M1 起逐步落盘，M3 项标注）：

```
docs/superpowers/specs/2026-11-24-gtd-app-design.md   # 本规格
pubspec.yaml                                           # Flutter 依赖声明
lib/main.dart                                          # 入口
lib/app/                                               # 路由、主题、响应式外壳
lib/core/                                              # ① GTD 核心层：领域模型、状态流转、用例（无 AI 依赖）
lib/data/                                              # Drift 表定义、Database、Repository、migrations/
lib/ai/                                                # ② AI 引擎层：AIClient、providers/、capabilities/（五能力）、prompts/、schemas/
lib/features/                                          # 收件箱 / 今日 / 理清向导 / 项目 / 情境 / 等待 / 回顾 / 设置
lib/i18n/                                              # ARB 中英文案
lib/sync/                                              # ③ 同步与云端（M3）
supabase/                                              # Edge Functions：AI 代理、同步（M3）
test/                                                  # 见 §11
```

---

## 13. 风险与缓解（Risks And Mitigations）

| # | 风险 | 缓解 |
|---|------|------|
| 1 | **AI 建议质量与幻觉**：错误解析、编造截止日，损害信任 | 确认权在用户（永不自动落库）；每条建议带 `why` + `confidence`；JSON Schema 校验失败重试后降级；Prompt 版本化可回滚；执行建议不落库、可"换一个" |
| 2 | **三里程碑范围膨胀**：中途不断加需求，拖垮交付 | 每个里程碑独立验收闸门（§8）；非目标清单（§2）作为新增需求的默认拒绝依据；五种 AI 能力独立、可单独裁剪 |
| 3 | **跨里程碑数据库演进**：M2 加 Reference、M3 加同步字段，重建数据库丢数据 | M1 即建立 `schemaVersion` 迁移机制；此后一切变更走迁移文件；备份导出功能在 M1 就位 |
| 4 | **桌面端本地模型环境差异**：Ollama 未安装/版本差异/本地端口不通 | AIClient 抽象 + `validateKey()` 连通性自检；配置引导；失败按 §9 降级，GTD 核心不受影响 |
| 5 | **M3 同步冲突复杂度**：字段级合并 + 手动选择容易出边界 bug | 冲突规则明确（§9.1）；M3 验收含专用冲突场景走查；同步引擎独立于核心层，失败不回滚本地数据 |
| 6 | **单用户架构阻碍将来多用户**：到处用全局单例导致 M3 大改 | M1 起强制 Repository + Provider 注入、无全局单例（§4.3）；多用户准备约束见 §10 |

---

## 14. 决策摘要（Decision Summary）

- **平台**：Flutter 单代码库，手机 + 桌面，`LayoutBuilder` 断点切换两套布局。
- **三层解耦**：GTD 核心层（无 AI 依赖）/ AI 引擎层（只出建议）/ 同步与云端层（M3）；每层独立开发测试。
- **数据**：本地 Drift/SQLite 为主库、离线优先；Supabase 账户 + 同步 + 服务端 AI 代理在 M3 引入。
- **数据模型**：6 核心实体（InboxItem / Task / Project / Context / Tag / Review）+ M2 加 Reference；收件箱为独立实体；等待 = Task 状态 + `waiting_on` 字段；删除为硬删除 + 二次确认。
- **AI 原则**：AI 只建议不落库、确认权在用户；建议必带 `why` / `confidence` / `prompt_version` / `model`；一键采纳或逐字段修改。
- **五种能力**：收集解析、智能理清、智能组织、智能回顾、执行建议，各自独立可裁剪。
- **模型抽象**：统一 `AIClient`（DeepSeek / OpenAI / Claude / Ollama）；BYOK 直连（M2）与 Supabase 服务端代理（M3）双模式；Key 加密存储。
- **输出约束**：JSON Schema 校验 + Prompt 版本化注册表；校验失败重试 1 次后降级。
- **离线/失败处理**：AI 失败指数退避重试、连续失败降级手动；离线时 AI 隐藏、GTD 照常；同步冲突字段级合并 + 最后写入优先 + 关键冲突手动选择。
- **界面**：收集零门槛（1–2 步）；AI 建议以徽标/卡片呈现，不强制弹窗；今日页 AI 执行建议卡片可"换一个"。
- **语言**：中英双语，默认跟随系统；M1 骨架、M3 全量。
- **里程碑**：方案 C 三层渐进——M1 GTD 核心地基（无 AI）→ M2 AI 引擎（BYOK）→ M3 云端与发布，各自独立交付。
- **测试**：四层（数据层 / AI 层 / 界面层 / 验收走查），每里程碑结束按验收清单走查。
