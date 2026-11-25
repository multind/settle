# v0.3 调度系统实施计划（时间粒度 + 重复规则 + 应用内提醒）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 截止/开始升级 date+time（含清除）；重复规则表单（每日/每周/每月/每 N 天）；应用内提醒（运行时到点 Banner）。重复生成逻辑已由数据层 `complete()` 事务承担，本计划只做 UI 侧接入。

**Architecture:** `TaskFormFields` 表单扩展（重复下拉/提醒选择/时间选择）；新增 `ReminderService`（Timer 轮询 + 内存去重）由响应式外壳挂载；`TaskDraft` 新字段（数据层已加）透传。

**Tech Stack:** Flutter、Material、Riverpod。

**Spec:** `docs/superpowers/specs/2026-11-25-v03-scheduling-design.md`

---

### Task 1: 表单时间粒度 + 重复 + 提醒

**Files:**
- Modify: `lib/features/task/task_form_fields.dart`
- Modify: `lib/features/task/task_edit_dialog.dart`（初始草稿带新字段）
- Modify: `test/widget/task_form_fields_test.dart`
- Modify: l10n（重复/清除/提醒等文案）

- [x] **Step 1: 时间选择器升级（due/scheduled）**

`_pickDate` 改为链式：`showDatePicker` → `showTimePicker`（默认 09:00；已有日期时
保留原时间）。展示 `yyyy-MM-dd HH:mm`（`intl` DateFormat 或手工 pad）。
行尾加「清除」`IconButton`（Key `clear_due`/`clear_scheduled`），置 null。

- [x] **Step 2: 重复下拉**

新增一行下拉「重复」（Key `task_repeat_field`）：无(null)/每日(daily)/每周(weekly)/
每月(monthly)/每 N 天(every)。选「每 N 天」时出现 `TextFormField`（Key
`task_repeat_interval`，1-365 正整数校验），值合成为 `every:N`。初始值来自
`initial.repeatRule`（反解析回下拉态）。

- [x] **Step 3: 提醒选择**

新增一行「提醒」（Key `task_reminder_field`）：date+time 选择（复用 Step 1 的
链式逻辑）+ 清除按钮（Key `clear_reminder`）。存 `reminderAt`。

- [x] **Step 4: validate 输出新字段**

`TaskDraft(repeatRule: ..., reminderAt: ...)`；`task_edit_dialog.dart` 的
`_initialDraft()` 补 `repeatRule`/`reminderAt` 回填。

- [x] **Step 5: task_form_fields_test 更新**

- date+time 选择流程（选日期后弹时间选择）
- 清除按钮 → 字段清空
- 重复下拉各值写对 repeatRule；每 N 天校验（N=0/-1/非数字拒绝）
- 提醒选择/清除
- 既有断言（截止日/计划/精力/优先级等）保持

- [x] **Step 6: analyze + 测试**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/features/task lib/i18n
flutter test test/widget/task_form_fields_test.dart 2>&1 | Select-Object -Last 1
```

Expected: 0 error；`All tests passed!`。

- [x] **Step 7: 提交**

```powershell
git add lib/features/task test/widget/task_form_fields_test.dart lib/i18n
git commit -m "feat(schedule): 截止/开始时间粒度 + 重复规则 + 提醒表单"
```

---

### Task 2: ReminderService + shell 挂载

**Files:**
- Create: `lib/features/task/reminder_service.dart`
- Modify: `lib/app/responsive_shell.dart`
- Create: `test/widget/reminder_service_test.dart`
- Modify: l10n（提醒/打开/知道了文案）

- [ ] **Step 1: 建服务**

`ReminderService`（纯 Dart，构造注入 `TaskRepository`）：
- `Timer.periodic(30s)`；每轮查 `reminderAt != null && reminderAt <= now &&
  reminderAt > 上轮时间 && status != done` 的任务（仓库加查询
  `watchDueReminders(int since, int now)`——**若数据层未含，本 Task 在
  task_repository.dart 补一个一次性查询方法**，返回 `List<Task>`）
- 内存 `Set<int> notifiedIds` 去重（同会话同任务只提醒一次）
- 暴露 `Stream<List<Task>> reminders` 或回调，供 UI 消费

- [ ] **Step 2: shell 挂载**

`ResponsiveShell` 的 State 持有服务实例（`initState` 启动、`dispose` 取消）；
监听提醒流 → `ScaffoldMessenger.showMaterialBanner`（或 SnackBar）：
「提醒：任务标题」+ [打开]（弹 `TaskEditDialog`）/ [知道了]（`hideCurrentMaterialBanner`
并标记已通知）。多条同时命中：串行展示或合并一条汇总。

- [ ] **Step 3: 测试**

`reminder_service_test.dart`：`FakeAsync` 推进 → 到点触发；同会话不重复；done
任务不触发；`reminderAt` 在窗口外不触发。

- [ ] **Step 4: analyze + 测试**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/features/task/reminder_service.dart lib/app/responsive_shell.dart
flutter test test/widget/reminder_service_test.dart 2>&1 | Select-Object -Last 1
```

Expected: 0 error；`All tests passed!`。

- [ ] **Step 5: 提交**

```powershell
git add lib/features/task/reminder_service.dart lib/app/responsive_shell.dart test/widget/reminder_service_test.dart lib/i18n
git commit -m "feat(schedule): 应用内到点提醒（Banner + 打开/知道了）"
```

---

### Task 3: 全量回归 + 收尾

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
```

Expected: 干净。

---

## 自审记录

- **Spec 覆盖**：§2 时间粒度→T1；§3 重复表单→T1（生成逻辑在数据层计划已落）；§4 提醒→T2；§5 验收→T1/T2/T3。完整覆盖。
- **占位符扫描**：无 TBD/TODO。
- **类型一致性**：`repeatRule` 字符串与 `RepeatRule.parse` 格式一致；`reminderAt` DateTime↔ms 转换复用仓库层现有写法。
- **依赖说明**：本计划依赖数据层计划（TaskDraft 新字段）与视图层计划（shell 结构）已落地。若依赖未合入，不得并行开工；ReminderService 所需的一次性查询若数据层未提供，在本计划 T2 Step 1 补齐并注明。
- **风险预案**：`Timer.periodic` 在 widget 测试中需 `FakeAsync`/`tester.pump(duration)` 驱动，测试已按此设计；MaterialBanner 与既有 SnackBar 可能冲突，实现时用 `ScaffoldMessenger` 的 banner 队列即可。
