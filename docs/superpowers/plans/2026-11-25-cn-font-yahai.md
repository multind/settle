# 中文字体指定微软雅黑 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Windows 中文渲染清晰（ThemeData 顶层 `fontFamily: 'Microsoft YaHei'`）。

**Architecture:** Flutter 的 `ThemeData.fontFamily` 会在 buildTextTheme 阶段传导到所有无显式 fontFamily 的 TextStyle，无需逐样式设置。浅/深主题共用同一调用点。

**Tech Stack:** Flutter、Material 主题系统。

**Spec:** `docs/superpowers/specs/2026-11-25-cn-font-yahai-design.md`

---

### Task 1: theme 加 fontFamily + 验证 + 提交

**Files:**
- Modify: `lib/app/theme.dart`

- [ ] **Step 1: 定位 ThemeData 构造**

读取 `lib/app/theme.dart` 中 `buildAppTheme` 的 `ThemeData(...)` 构造（约第 271-473 行），确认顶层参数列表（应含 `scaffoldBackgroundColor`、`colorScheme`、各组件主题）。确认**当前无 fontFamily**（全仓 grep `fontFamily` 应仅在 theme.dart 组件主题的 TextStyle 内出现过 fontSize，无 fontFamily 设置——如有则调整）。

- [ ] **Step 2: 添加 fontFamily**

在 ThemeData 构造顶层参数中添加（放在 `scaffoldBackgroundColor` 附近，与其他顶层参数同级）：

```dart
      // Windows 中文清晰渲染（spec：中文字体指定微软雅黑）。
      fontFamily: 'Microsoft YaHei',
```

- [ ] **Step 3: analyze**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/app/theme.dart
```

Expected: 0 error（SDK 级 material.dart 弃用 info 除外）。

- [ ] **Step 4: 全量回归**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（96/96；widget 测试不依赖字体族）。

- [ ] **Step 5: 提交**

```powershell
git add lib/app/theme.dart
git commit -m "fix(theme): 指定微软雅黑，Windows 中文清晰渲染"
```

提交后 `git log --oneline -1` 确认；`git status --short` 确认工作区干净。

---

## 自审记录

- **Spec 覆盖**：§4（fontFamily 单点改动）→Task 1 Step 2；§5（analyze/全量回归）→Steps 3-4。完整覆盖。
- **占位符扫描**：无 TBD/TODO；改动为单行参数。
- **类型一致性**：`fontFamily` 为 ThemeData 顶层 String? 参数，写法标准；TextTheme 传导机制为 Flutter 内置（theme.fontFamily 应用到无显式 fontFamily 的样式），无需改动 textTheme 块。
