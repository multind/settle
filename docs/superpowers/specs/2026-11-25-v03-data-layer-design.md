# v0.3 数据层设计（schema v2 + 任务仓库扩展）

日期：2026-11-25
状态：已批准（v0.3 设计定稿用户确认，本 spec 为其数据层部分）
前置：Things 3 化重构收官（HEAD `627425c`，工作区干净）

## 1. 背景与目标

v0.3 补齐 GTD 时间维度与桌面效率（设计定稿 2026-11-25 已确认）：四个视图
（今日改造/随时/即将/日志）、调度系统（时间粒度/重复/应用内提醒）、交互层
（拖拽/多选/快捷键）。本 spec 是**数据层地基**——为视图、调度、交互提供字段
与查询能力。视图/调度/交互分别由配套 spec 覆盖，实施按依赖顺序分阶段。

## 2. 决策记录（用户逐项确认，与本 spec 相关部分）

| 决策点 | 结论 |
|---|---|
| 视图划分 | 有日期按日期走（今日/即将），无日期进随时，逾期置顶，完成进日志 |
| 调度边界 | 时间粒度 + 重复规则 + 应用内提醒（运行时弹提示） |
| 交互层 | 全做（拖拽重排/拖到日期/多选批量/键盘快捷键），不做跨区拖拽 |

## 3. schema v1 → v2（迁移，现有数据不丢）

**Tasks 表新增 4 列：**

| 列 | 类型 | 语义 |
|---|---|---|
| `completedAt` | `integer().nullable()` | 完成时间戳（ms epoch）；null = 未完成 |
| `sortOrder` | `integer().withDefault(const Constant(0))()` | 手动重排顺序；列表查询主排序键 |
| `repeatRule` | `text().nullable()` | 重复规则（见 §4.3 格式）；null = 不重复 |
| `reminderAt` | `integer().nullable()` | 提醒时间（ms epoch）；null = 无提醒 |

**迁移步骤（schemaVersion 1 → 2）：**
1. `ALTER TABLE tasks ADD COLUMN completedAt INTEGER`（nullable，缺省 NULL）
2. `ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0`
3. `ADD COLUMN repeatRule TEXT`（nullable）
4. `ADD COLUMN reminderAt INTEGER`（nullable）
5. **回填** `UPDATE tasks SET sortOrder = id`——既有任务按 id 顺序，与旧查询
   （order by id）保持等价，现有测试不因排序键变更而失效。

**日期存储语义**：`scheduled`/`dueDate` 维持 `integer()`（ms epoch），本就支持
datetime 精度（`TaskRepository` 已存 `draft.dueDate?.millisecondsSinceEpoch`）。
**"时间粒度升级"是 UI 层职责**（picker 加时间选择），数据层无改动。

## 4. 任务仓库（TaskRepository）扩展

### 4.1 新查询（视图 spec 依赖）

| 方法 | 语义 |
|---|---|
| `watchToday()` | `status=next_action && (scheduled ≤ 今日23:59:59.999 \|\| dueDate ≤ 今日23:59:59.999)` |
| `watchAnytime()` | `status=next_action && scheduled IS NULL && dueDate IS NULL` |
| `watchUpcoming()` | `status=next_action && (scheduled > 今日23:59:59.999 \|\| dueDate > 今日23:59:59.999)` |
| `watchDone()` | `status=done`，按 `completedAt DESC`（null 最后）→ `id DESC` 排序 |

排序约定：视图类查询统一 `ORDER BY sortOrder ASC, id ASC`（`watchByStatus` 等
既有查询同步改为该排序；回填保证与旧顺序等价）。

### 4.2 状态流转扩展（生命周期 spec 语义）

- `create()`：插入后回填 `sortOrder = id`（与旧 id 序等价）；透传新增字段
- `update()`：透传 `completedAt`/`sortOrder`/`repeatRule`/`reminderAt`
- `setStatus(id, done)`：额外写 `completedAt = now`
- `setStatus(id, 非 done)`：**清空** `completedAt = null`（恢复/改状态时不残留完成时间）
- `complete(id)`：= `setStatus(done)` + **重复任务生成下一次**（§4.4，事务内）
- `reopen(id)`：= `setStatus(nextAction)`（completedAt 自动清空）
- `reorder(List<int> orderedIds)`：事务内按列表顺序写 `sortOrder = index`——
  重排的唯一落库入口（视图层 ReorderableListView 提供新顺序）

### 4.3 重复规则格式与推进（新增 `lib/core/models/repeat_rule.dart`）

存储为简单字符串：

| 值 | 推进规则 |
|---|---|
| `daily` | +1 天 |
| `weekly` | +7 天（保持星期几） |
| `monthly` | +1 月，**月末钳制**（1/31 → 2/28/29，Dart 直接 `month+1` 会溢出到 3 月，需钳制到当月最后一天） |
| `every:N` | +N 天（N≥1，自定义间隔） |

提供 `RepeatRule.parse(String?)` 与 `nextDate(DateTime)`。无效值视为 null（不重复）。

### 4.4 完成时生成下一次（事务内）

`complete(id)` 且任务带 `repeatRule` 时，同一事务：
1. 原任务 → done + `completedAt=now`（进日志）
2. 插入新副本：克隆 title/notes/projectId/contextId/tags/energy/priority；
   `status=next_action`；`scheduled`/`dueDate` 各自按规则推进（有则推，无则保持 null）；
   `reminderAt` 同样推进；`completedAt=null`；`sortOrder` 取当前 max+1

### 4.5 导出/导入往返（防丢调度数据）

`ExportService` 的 JSON 增加 `completedAt`/`sortOrder`/`repeatRule`/`reminderAt`
字段，导入时还原（缺失字段容错为 null/默认）。既有备份文件向后兼容。

## 5. 测试与验收

- `migration_test.dart` 更新：v1 → v2 迁移后 4 新列存在、回填 sortOrder=id 正确
- `task_repository_test.dart` 新增：watchToday/Anytime/Upcoming/Done 边界、
  complete 写 completedAt、reopen 清空、reorder 持久化、重复规则 4 类推进
  （含 1/31→2/28 月末钳制）、complete 生成副本且原任务进 done
- `export_service_test.dart` 更新：新字段往返
- 既有 96 项测试：排序键从 id → sortOrder 后顺序等价（回填保证），预期不破；
  如破按新语义更新断言

## 6. 范围外

- 不改 `scheduled`/`dueDate` 存储类型（ms epoch 已支持 datetime）
- 不做系统级通知（应用内提醒由调度 spec 覆盖，符合主规格 §2 非目标）
- 不做跨区拖拽的数据支撑
