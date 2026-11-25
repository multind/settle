# 字体族改 Microsoft YaHei UI 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** "将"字等字形改为 Microsoft YaHei UI 族正常字形（单行改动）。

**Architecture:** `theme.dart:306` 的 `fontFamily` 由 `'Microsoft YaHei'` 改为 `'Microsoft YaHei UI'`。Flutter 的 ThemeData.fontFamily 传导机制不变（应用到所有无显式 fontFamily 的 TextStyle）。

**Tech Stack:** Flutter、Material 主题系统。

**Spec:** `docs/superpowers/specs/2026-11-25-cn-font-yahai-ui-design.md`

---

### Task 1: fontFamily 改 UI 族 + 验证 + 提交

**Files:**
- Modify: `lib/app/theme.dart`

- [ ] **Step 1: 定位 fontFamily**

读取 `lib/app/theme.dart` 第 306 行一带，确认为 `fontFamily: 'Microsoft YaHei',`（前置修复 7b9d421 所加）。

- [ ] **Step 2: 改 UI 族**

将第 306 行替换为：

```dart
    fontFamily: 'Microsoft YaHei UI',
```

注释（上一行）同步为：`// Windows 中文 UI 族字形（"将"字等正常渲染）。`（以实际注释文字为准，仅更新为 UI 族语义。）

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

Expected: `All tests passed!`（96/96）。

- [ ] **Step 5: 提交**

```powershell
git add lib/app/theme.dart
git commit -m "fix(theme): 字体族改 Microsoft YaHei UI（将字等字形正常）"
```

提交后 `git log --oneline -1` 确认；`git status --short` 确认工作区干净。

---

## 自审记录

- **Spec 覆盖**：§4（fontFamily 单行改动）→Task 1 Step 2；§5（analyze/全量回归）→Steps 3-4。完整覆盖。
- **占位符扫描**：无 TBD/TODO；改动为单行字符串 + 注释。
- **类型一致性**：`fontFamily` 为 ThemeData 顶层 String? 参数，改值不改签名；无其他文件受影响。
