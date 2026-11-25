# FAB 按页互斥实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复「+按钮语义混乱」：项目/情境/回顾页只显示页面新建 FAB，其余可收集页保留全局收集 FAB。

**Architecture:** 单文件逻辑改动——`ResponsiveShell` 外壳 FAB 的显示条件从「非收件箱页」收窄为「非收件箱页且非项目/情境/回顾页」；页面自身 FAB 与全部对话框逻辑不动。

**Tech Stack:** Flutter（ResponsiveShell / NavigationRail / FAB）、flutter_test（widget 测试）。

**Spec:** `docs/superpowers/specs/2026-11-25-fab-per-page-design.md`

---

### Task 1: FAB 显示条件按页互斥 + 测试断言

**Files:**
- Modify: `lib/app/responsive_shell.dart:95`
- Modify: `test/widget/responsive_shell_test.dart`

- [x] **Step 1: 修改外壳 FAB 显示条件**

将 `lib/app/responsive_shell.dart` 第 95 行 `floatingActionButton: _index != 0` 改为：

```dart
floatingActionButton: _index != 0 && !const {2, 3, 6}.contains(_index)
```

（2=项目 ProjectsPage、3=情境 ContextsPage、6=回顾 ReviewPage——这些页用各自的 `new_project_fab`/`new_context_fab`/`new_review_fab`。）

用 edit 工具精确替换 `_index != 0\n              ? FloatingActionButton(` 为 `_index != 0 && !const {2, 3, 6}.contains(_index)\n              ? FloatingActionButton(`。

- [x] **Step 2: 修改测试——情境页断言**

在 `test/widget/responsive_shell_test.dart` 中修改「侧边栏切到情境页并展示情境（验收①⑤）」测试，在 `expect(find.text('@电脑'), findsOneWidget);` 之后追加两行：

```dart
    // 按页互斥（spec 2026-11-25）：情境页只显示新建 FAB，不显示全局收集 FAB
    expect(find.byKey(const Key('new_context_fab')), findsOneWidget);
    expect(find.byKey(const Key('global_collect_fab')), findsNothing);
```

- [x] **Step 3: 修改测试——今日页回归断言**

在「非收件箱页全局 FAB 一步收集（验收②）」测试中，`await tester.tap(find.text('Today'));` 与 `await tester.pumpAndSettle();` 之后追加：

```dart
    // 按页互斥（spec 2026-11-25）：今日页无页面级 FAB，仍显示全局收集 FAB
    expect(find.byKey(const Key('global_collect_fab')), findsOneWidget);
```

- [x] **Step 4: 运行两个测试文件**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test test/widget/responsive_shell_test.dart
```

Expected: 4/4 全绿（2 布局 + 情境页互斥断言 + 今日页收集回归）。

- [x] **Step 5: 全量回归 + analyze**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
flutter analyze 2>&1 | Select-String -Pattern 'error' | Select-Object -First 5
```

Expected: `All tests passed!`（96/96）；无 error 输出行。

- [x] **Step 6: 提交**

```powershell
git add lib/app/responsive_shell.dart test/widget/responsive_shell_test.dart
git commit -m "fix(ui): FAB 按页互斥（项目/情境/回顾显示新建，其余显示收集）"
```

提交后 `git log --oneline -1` 确认；`git status --short` 确认工作区干净。

---

## 自审记录

- **Spec 覆盖**：§4（单文件条件改动）→Task 1 Step 1；§5（两个测试断言 + 96/96 回归）→Task 1 Steps 2-5。完整覆盖。
- **占位符扫描**：无 TBD/TODO；每步含精确代码/命令与预期输出。
- **类型一致性**：页面下标 {2,3,6} 与 `_pages` 顺序一致（收件箱0/今日1/项目2/情境3/等待4/将来也许5/回顾6/设置7），与 spec §3 表格一致；Key 名与各页现有 FAB 一致。
