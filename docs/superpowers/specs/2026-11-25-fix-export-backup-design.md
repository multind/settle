# 修复导出备份不落盘（桌面平台 saveFile 不写文件）

日期：2026-11-25
状态：已批准（用户确认修复方案）
前置：FAB 按页互斥已收官（HEAD `d0f95ca`，工作区干净）

## 1. 问题

用户反馈：设置页「导出备份」显示成功，但磁盘上没有文件。

根因：`file_picker` 插件在桌面平台（Windows/macOS/Linux）的 `saveFile()` **只打开
"另存为"对话框并返回用户选择的路径，不创建文件**（官方文档
`file_picker.dart:160-162` 明示；`bytes` 参数仅 Android/iOS 会写入）。
当前 `FilePickerBackupGateway.saveBackup()` 直接 `return FilePicker.platform.saveFile(bytes: ...)`，
拿到路径后没有任何落盘动作，因此显示成功但文件不存在。

## 2. 目标

桌面平台导出备份后，用户所选路径处真实生成 JSON 文件。

## 3. 方案

拿到 `saveFile()` 返回路径后，调用 `File(path).writeAsBytes(bytes)` 真正写盘。
用户取消（返回 null）时不写、不弹成功提示（保持现状）。

## 4. 实现（单文件改动）

**`lib/features/settings/backup_file_gateway.dart`** 的 `saveBackup`：

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

需确认 `dart:io` 已 import（该文件当前只 import `dart:convert`/`dart:typed_data`，
需补 `import 'dart:io';`）。

## 5. 测试

- 现有 widget 测试用 `FakeBackupGateway`（test/widget/widget_utils.dart），不受影响。
- 全量 `flutter test` 保持 96/96；`flutter analyze` 0 error。
- 真机验证：重建安装包后，设置页导出 → 选路径保存 → 磁盘上出现 JSON 文件，
  内容含 inbox_items/projects/contexts/tags/tasks/task_tags/reviews。

## 6. 范围外

- 不改导入逻辑（导入本身正常）。
- 不改对话框标题/默认文件名。
- 不引入其他文件改动。
