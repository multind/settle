# v0.3 交互层实施计划（拖拽重排 + 拖到日期 + 多选批量 + 键盘快捷键）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 公共 `TaskListView`（重排/多选/焦点）+ 批量操作 + 即将视图拖到日期 + 桌面键盘快捷键。

**Architecture:** 单一公共组件收敛六视图任务列表；`reorder()`（数据层已落库 sortOrder）；拖到日期用 `Draggable`/`DragTarget` + `setScheduled`；快捷键 shell 层 `Shortcuts/Actions` + 列表层焦点行（J/K/Enter/Delete）。

**Tech Stack:** Flutter、Material（ReorderableListView/Draggable/Shortcuts）。

**Spec:** `docs/superpowers/specs/2026-11-25-v03-interaction-design.md`

---

### Task 1: TaskListView 公共组件 + 六视图接入

**Files:**
- Create: `lib/features/task/task_list_view.dart`
- Modify: 今日/随时/即将/等待/将来也许/日志 六页（换用公共组件）
- Modify: l10n（已选 N 项等文案）

- [x] **Step 1: 组件骨架**

`TaskListView`（ConsumerStatefulWidget）参数：`tasks`、`reorderEnabled`、
`selectionEnabled`、`focusEnabled`、`onAction`（批量操作回调，Task 2 接）、
`buildDateHeader`（即将页注入日期头，见 Task 3）。

内部三态：
- **普通**：行渲染沿用 v0.2 样式（完成钮/编辑对话框）
- **重排**：`ReorderableListView`，`onReorder` → 重排后 `repository.reorder(orderedIds)`
- **选择**：长按行进入；行前 `GlassCheckbox` 勾选（点选切换）；顶栏「已选 N 项」
  + 操作按钮 + 退出 X

互斥：重排模式不触发长按多选；多选模式禁用拖动。

- [x] **Step 2: 焦点行（桌面）**

`focusEnabled` 时维护 `_focusIndex`：行可获焦（`FocusNode`/`InkWell` focus 高亮），
供快捷键 Enter/Delete 操作（Task 4 接线）。

- [x] **Step 3: 六视图接入**

- 今日/随时/等待/将来也许：`reorderEnabled`（今日/随时 ✅，等待/将来也许按 spec
  可选——**今日/随时开、等待/将来也许关**）、`selectionEnabled ✅`、`focusEnabled ✅`
- 即将：组内 `reorderEnabled ✅`、`selectionEnabled ✅`、`focusEnabled ✅`；
  组头由 `buildDateHeader` 注入
- 日志：`reorderEnabled ❌`、`selectionEnabled ✅`（操作=恢复/删除子集）、
  `focusEnabled ✅`

替换各页既有 `_TaskTile` 私有行（保留 Key 约定 `task_tile_$id`/`task_done_$id`，
测试兼容）。

- [x] **Step 4: 测试**

`task_list_view_test.dart`：普通渲染；长按进选择模式 + 点选切换；退出；重排
`onReorder` 触发 `reorder()` 落库（断言 sortOrder 持久化）；重排/多选互斥。

- [x] **Step 5: analyze + 测试**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/features/task/task_list_view.dart lib/features lib/i18n
flutter test test/widget/task_list_view_test.dart 2>&1 | Select-Object -Last 1
```

Expected: 0 error；`All tests passed!`。

- [x] **Step 6: 提交**

```powershell
git add lib/features/task/task_list_view.dart lib/features lib/i18n test/widget/task_list_view_test.dart
git commit -m "feat(ui): TaskListView 公共组件（重排/多选/焦点）接入六视图"
```

> **自审登记（产品决策）**：排序收敛为「优先级 → sortOrder → id 升序（终局 tiebreak）」
> 改变了今日视图既有展示顺序（原 views spec 为「优先级 → 生效日期」）。跨优先级
> 排序由统一比较器决定，重排仅持久化 sortOrder、在同一优先级段内生效。此决策已
> 由 spec 合规审查确认，后续如需恢复「生效日期」次级排序请在 views spec 内修订。

---

### Task 2: 批量操作动作

**Files:**
- Modify: `lib/features/task/task_list_view.dart`（动作回调实现）
- Modify: 各页（传批量操作参数）
- Modify: l10n（完成/删除/设日期/移动/恢复文案）

- [x] **Step 1: 动作面板**

选择模式顶栏按钮（按视图裁剪）：
- **完成**：`complete` 批量（重复任务各自生成下一次）
- **删除**：确认对话框 → `delete` 批量
- **设日期**：对话框（截止/开始 二选一 + 日期选择）→ `update` 批量（经 TaskDraft）
  或仓库批量方法
- **移动**：项目下拉对话框 → 批量写 `projectId`（`setProject`）
- **恢复**（日志）：批量 `reopen`

- [x] **Step 2: 接线**

各页 `onAction` 回调传对应操作集（日志子集：恢复/删除）。

- [x] **Step 3: 测试**

批量完成 → 全部 done + 重复任务生成副本；批量删除 → 确认后全部消失；设日期 →
全部写入；移动 → 全部改项目；日志恢复 → 全部 next_action。

- [x] **Step 4: analyze + 测试 + 提交**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/features/task lib/i18n
flutter test test/widget/task_list_view_test.dart 2>&1 | Select-Object -Last 1
git add lib/features/task lib/i18n test/widget/task_list_view_test.dart
git commit -m "feat(ui): 多选批量操作（完成/删除/设日期/移动/恢复）"
```

> **自审登记（偏差）**：接线形态为「六页传 `actions:` 操作集裁剪（Task 1 已配置）+ 组件内置默认处理」，
> `onAction` 留作可选委托钩子（当前无调用方）——与 spec §6 行为等价；新增仓库单列方法
> `setDueDate`（镜像 setScheduled，因 `update(TaskDraft)` 会重建 taskTags 绑定，不适合作批量
> 仅改截止日的场景）。批量动作相关 Minor（循环 try/finally、测试固定时钟、移动对话框 loading
> 禁 OK、onAction 异步签名）记入收尾清单统一处理。

---

### Task 3: 拖到日期（即将视图）

**Files:**
- Modify: `lib/features/upcoming/upcoming_page.dart`
- Modify: `test/widget/upcoming_page_test.dart`

- [ ] **Step 1: Draggable + DragTarget**

即将行包 `Draggable<int>(taskId)`（拖动数据=任务 id）；日期头包
`DragTarget<int>`（Key `upcoming_date_drop_${y}_${m}_${d}`）：
- `onWillAccept`：目标日期 ≠ 任务当前 scheduled
- `onAccept`：`repository.setScheduled(id, 目标日)`；任务即时移到对应日期组
  （或按语义落入今日——目标日 ≤ 今日时）
- 落点悬停高亮（日期头描边 `primary`）

- [ ] **Step 2: 测试**

拖任务到另一日期头 → `scheduled` 写入目标日、分组即时变化；拖到已过日期 → 落
今日语义；不合法目标（当前日期）不接受。

- [ ] **Step 3: analyze + 测试 + 提交**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/features/upcoming
flutter test test/widget/upcoming_page_test.dart 2>&1 | Select-Object -Last 1
git add lib/features/upcoming test/widget/upcoming_page_test.dart
git commit -m "feat(upcoming): 拖拽任务到日期头 = 安排开始日期"
```

---

### Task 4: 键盘快捷键

**Files:**
- Modify: `lib/app/responsive_shell.dart`
- Modify: `lib/features/task/task_list_view.dart`（焦点快捷键）
- Modify: `test/widget/responsive_shell_test.dart`
- Modify: l10n（快捷键 tooltip 文案，可选）

- [ ] **Step 1: shell 层全局快捷键（Shortcuts/Actions/Intent）**

桌面平台（`kIsWeb || Platform.isWindows/Linux/macOS`）启用；文本输入焦点时
不拦截（`FocusManager.instance.primaryFocus` 落在 `EditableText` 则跳过）：
- `N` → 打开 `CollectDialog`
- `Ctrl/Cmd+1..9` → 侧边栏第 1..9 项（收件箱..日志）
- `Ctrl/Cmd+0` → 回顾（index 9）

- [ ] **Step 2: 列表层焦点快捷键**

`TaskListView` 焦点行（Task 1 已建焦点态）：`J`/`K` 上下移焦点（列表内循环）、
`Enter` 完成焦点任务、`Delete` 删除焦点任务（确认对话框）。仅 `focusEnabled`
且桌面时生效。

- [ ] **Step 3: 测试**

快捷键：N 打开收集对话框；Ctrl+2 切今日；Ctrl+5 切将来也许；输入框聚焦时 N
不触发；J/K 焦点移动 + Enter 完成 + Delete 确认删除（列表层测试，用
`tester.sendKeyEvent`）。

- [ ] **Step 4: analyze + 测试 + 提交**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/app/responsive_shell.dart lib/features/task
flutter test test/widget/responsive_shell_test.dart test/widget/task_list_view_test.dart 2>&1 | Select-Object -Last 1
git add lib/app/responsive_shell.dart lib/features/task test/widget
git commit -m "feat(shortcuts): 桌面快捷键（N/数字切视图/JK/Enter/Delete）"
```

---

### Task 5: 全量回归 + 收尾

- [ ] **Step 1: 全量测试**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`。

- [ ] **Step 2: 全仓 analyze**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze 2>&1 | Select-Object -Last 3
```

Expected: 0 error（既有 SDK 弃用 info / 旧基线 warning 除外）。

- [ ] **Step 3: 工作区确认**

```powershell
git status --short
git log --oneline -8
```

Expected: 干净；交互层各 Task 提交齐全。

---

## 自审记录

- **Spec 覆盖**：§2 公共组件→T1；§3 重排→T1；§4 拖到日期→T3；§5 快捷键→T4；§6 多选批量→T2；§7 验收→各 Task + T5。完整覆盖。
- **占位符扫描**：无 TBD/TODO。
- **类型一致性**：`Draggable<int>` 携带 taskId，`DragTarget<int>` 落点类型一致；`reorder(List<int>)` 与 `setScheduled(int, DateTime?)` 均为数据层已定签名。
- **依赖说明**：依赖数据层（reorder/setScheduled）与视图层（六页结构与 Key 约定）已落地。
- **风险预案**：ReorderableListView 在即将页跨组拖动的组头 DragTarget 冲突——已通过「组内重排 + 拖到日期头」隔离；快捷键与既有 TextField 快捷键（如 Ctrl+A 全选）冲突——已通过 EditableText 焦点检查规避；批量操作对话框（设日期/移动）复用 `showDatePicker`/项目下拉既有组件。
