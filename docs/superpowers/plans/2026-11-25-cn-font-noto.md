# 字体族改思源黑体 Noto Sans SC 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 中文改用思源黑体 Noto Sans SC（Skia 渲染优于雅黑，单行改动）。

**Architecture:** `theme.dart` 的 `fontFamily` 由 `'Microsoft YaHei UI'` 改为 `'Noto Sans SC'`。系统已装该字体（NotoSansSC-VF.ttf），零体积。Flutter 的 ThemeData.fontFamily 传导机制不变。

**Tech Stack:** Flutter、Material 主题系统。

**Spec:** `docs/superpowers/specs/2026-11-25-cn-font-noto-design.md`

---

### Task 1: fontFamily 改思源黑体 + 验证 + 提交

**Files:**
- Modify: `lib/app/theme.dart`

- [ ] **Step 1: 定位 fontFamily**

读取 `lib/app/theme.dart`（约第 306 行一带），确认为 `fontFamily: 'Microsoft YaHei UI',`（前置修复 ef11e80 所加）。

- [ ] **Step 2: 改思源黑体**

将 fontFamily 行替换为：

```dart
    fontFamily: 'Noto Sans SC',
```

上一行注释同步更新为思源黑体语义（如：`// Windows 中文用思源黑体（Skia 渲染优于雅黑）。`；以实际注释文字为准，仅改语义不扩展内容）。

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
git commit -m "fix(theme): 字体族改思源黑体 Noto Sans SC（Skia 渲染优于雅黑）"
```

提交后 `git log --oneline -1` 确认；`git status --short` 确认工作区干净。

---

## 自审记录

- **Spec 覆盖**：§4（fontFamily 单行改动）→Task 1 Step 2；§5（analyze/全量回归）→Steps 3-4。完整覆盖。
- **占位符扫描**：无 TBD/TODO；改动为单行字符串 + 注释。
- **类型一致性**：`fontFamily` 为 ThemeData 顶层 String? 参数，改值不改签名；无其他文件受影响。
- **风险预案**：若真机出现 VF 渲染异常，按 spec §5 回退方案 C（YaHei UI）或改 B（捆绑）。本任务不触发，仅在汇报中提示。
