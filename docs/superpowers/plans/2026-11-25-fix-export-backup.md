# 修复导出备份不落盘 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 桌面平台导出备份时真实写盘（修复「显示成功但无文件」）。

**Architecture:** 在 `FilePickerBackupGateway.saveBackup()` 中，`saveFile()` 返回路径后追加 `File(path).writeAsBytes(bytes)`。桌面平台 `saveFile` 不写文件（file_picker 官方行为），必须自行落盘；Android/iOS 平台由插件写入（保留 bytes 参数）。

**Tech Stack:** Flutter、dart:io、file_picker 8.3.7。

**Spec:** `docs/superpowers/specs/2026-11-25-fix-export-backup-design.md`

---

### Task 1: saveBackup 追加真实写盘

**Files:**
- Modify: `lib/features/settings/backup_file_gateway.dart`
- Test: 全量回归（96/96）

- [ ] **Step 1: 确认当前文件头 import**

读取 `lib/features/settings/backup_file_gateway.dart` 前 5 行。当前应为：

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

确认后进入 Step 2。

- [ ] **Step 2: 添加 `dart:io` import**

在 `import 'dart:convert';` 之前插入 `import 'dart:io';`（按字母序 dart:io 在 dart:convert 前）：

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
```

- [ ] **Step 3: 修改 saveBackup 落盘**

将 `lib/features/settings/backup_file_gateway.dart` 的 `saveBackup` 方法（当前第 17-23 行）替换为：

```dart
  @override
  Future<String?> saveBackup(String json) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export GTD backup',
      fileName: 'gtd_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      bytes: bytes, // 保留：Android/iOS 平台由插件写入
    );
    if (path == null) return null; // 用户取消
    await File(path).writeAsBytes(bytes); // 桌面平台真正落盘
    return path;
  }
```

- [ ] **Step 4: analyze 该文件**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/features/settings/backup_file_gateway.dart
```

Expected: 无 error（SDK 级 material.dart 弃用 info 除外，本文件应无输出或仅 info）。

- [ ] **Step 5: 全量回归**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（96/96，FakeBackupGateway 不受影响）。

- [ ] **Step 6: 提交**

```powershell
git add lib/features/settings/backup_file_gateway.dart
git commit -m "fix(settings): 导出备份桌面平台真实写盘（saveFile 不写文件）"
```

提交后 `git log --oneline -1` 确认；`git status --short` 确认工作区干净。

---

## 自审记录

- **Spec 覆盖**：§4（import + saveBackup 落盘）→Task 1 Steps 2-3；§5（analyze/全量回归）→Steps 4-5。完整覆盖。
- **占位符扫描**：无 TBD/TODO；代码逐字给出。
- **类型一致性**：`File(path).writeAsBytes(bytes)` 使用 dart:io 的 `File`，与新增 import 一致；`bytes` 变量在写盘处仍可用（同作用域）。
