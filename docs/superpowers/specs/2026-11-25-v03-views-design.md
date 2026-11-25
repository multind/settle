# v0.3 视图层设计（今日改造 + 随时/即将/日志 + 导航重组）

日期：2026-11-25
状态：已批准（v0.3 设计定稿用户确认，本 spec 为其视图层部分）
依赖：数据层 spec（`2026-11-25-v03-data-layer-design.md`）——新查询
`watchToday/watchAnytime/watchUpcoming/watchDone` 与 `completedAt` 字段
前置：HEAD `627425c`，工作区干净

## 1. 背景与目标

v0.3 视图模型（用户确认）：**有日期的按日期走（今日/即将），无日期进随时，
逾期置顶，完成进日志**。本 spec 定义四个视图的语义、结构与导航重组。

## 2. 导航重组（侧边栏 8→11 项分组，底部 5 项时间优先）

### 2.1 视图索引（全局固定顺序）

```
0 收件箱  1 今日  2 即将  3 随时  4 将来也许
5 项目    6 情境  7 等待  8 日志  9 回顾  10 设置
```

### 2.2 宽屏侧边栏（≥600px）

**替换 NavigationRail 为自定义可滚动分组侧边栏**（11 项 rail 会溢出且无法分组；
Things 3 正是分组列表侧边栏）。结构：

```
GTD（品牌字，固定顶部）
──────────────────
收件箱                     ← 无分组标题，置顶
时间                        ← 分组标题（muted 小字）
  今日 / 即将 / 随时 / 将来也许
组织
  项目 / 情境 / 等待
系统
  日志 / 回顾 / 设置
```

视觉沿用 v0.2：纯底（`tokens.sidebar`）+ 右侧 1px `stroke` hairline；选中项
`selectedBg` 圆角底 + `primary` 图标/文字；组标题 `muted` 12px。可滚动
（`ListView`），避免矮窗口溢出。

### 2.3 窄屏底部导航（<600px）

5 项：**收件箱 / 今日 / 即将 / 随时 / 更多**。
「更多」点击弹 `showModalBottomSheet`：项目/情境/等待/日志/回顾/设置 列表项，
点选即切换视图并关 sheet。底部栏沿用 v0.2 纯底 + 顶部 1px hairline。

### 2.4 FAB 显隐重映射

沿用现语义（隐藏于有专属新建/操作入口的页），按新索引：隐藏于
收件箱(0)/项目(5)/情境(6)/回顾(9)；其余页（今日/即将/随时/将来也许/等待/日志/
设置）显示全局收集 FAB。

## 3. 今日（改造，index 1）

**查询**：`watchToday()`（next_action 且 开始≤今日 或 截止≤今日）。

**分区**：
1. **逾期区**（`dueDate != null && dueDate < 今日 00:00`）：顶部独立区块，
   左侧/底色用 `tokens.danger` 弱化标记（如 1px 左侧色条 + danger 日期文字），
   标题「逾期 n 项」
2. **今日区**：其余任务，按 优先级→生效日期（scheduled ?? dueDate）升序

**行**：沿用 v0.2 任务行（完成钮/编辑对话框/完成→done+completedAt→进日志）。
行组件抽公共 `TaskListView`（交互 spec 统一定义，此处先给出需求）。

**空态**：无任务时显示空态文案（区分「今日无安排」与「完全无任务」）。

## 4. 随时（新，index 3）

**查询**：`watchAnytime()`（next_action 且无 scheduled 无 dueDate）。

- 排序：优先级 → sortOrder
- 行：同公共任务行；完成→进日志
- 这是「无主时间」清单：无日期任务唯一去处，Today 不再显示它们

## 5. 即将（新，index 2）

**查询**：`watchUpcoming()`（next_action 且 scheduled/dueDate 在未来）。

**结构**：按生效日期（`scheduled ?? dueDate`）的**日期分组时间线**，升序。
- 日期头：`MM月dd日 周几`（近两天可用「明天/后天」友好文案），`muted` 小字
- 组内任务按 优先级→sortOrder
- 日期头同时是**拖拽落点**（DragTarget，拖任务到该日期 = 安排 scheduled，
  交互 spec 实现）
- 空态：无未来安排文案

## 6. 日志（新，index 8）

**查询**：`watchDone()`（done 按 completedAt DESC，null 最后）。

- **搜索框**：顶部 TextField，按标题包含过滤（大小写不敏感）
- 行：标题 + 完成日期（`completedAt` 格式化）；动作为 **恢复**（reopen → 回
  next_action 并按日期落入今日/随时）与 **删除**（硬删除，确认对话框）
- 空态：无完成记录文案

## 7. 测试与验收

- `responsive_shell_test.dart` 更新：宽屏断言自定义侧边栏 3 组 11 项（按 key/
  文本）；窄屏断言 5 项底部 + 「更多」sheet 项
- `today_page_test.dart` 更新（语义变更）：今日只显示有日期（scheduled/dueDate
  今日或逾期）的 next_action；**无日期 next_action 不出现**（进随时，由
  anytime_page_test 覆盖）；逾期区置顶；完成→done
- 新增 `anytime_page_test.dart`：无日期任务显示、有日期不显示、完成流转
- 新增 `upcoming_page_test.dart`：按日期分组、生效日期=scheduled??dueDate、
  空态
- 新增 `logbook_page_test.dart`：completedAt 倒序、搜索过滤、恢复/删除
- l10n 全量新增文案（中英双语）：导航新项/更多/逾期/组标题/空态等

## 8. 范围外

- 不做 Things 的 This Evening 分区、7 天预览条、项目休眠
- 不做日志的统计图表（回顾页统计维持现状）
- 不做跨区拖拽（拖到项目/情境）
