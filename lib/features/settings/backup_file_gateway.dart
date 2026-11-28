import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 备份文件读写抽象（Widget 测试替换为 Fake，规避 file_picker 插件缺失）。
abstract class BackupFileGateway {
  /// 保存 JSON 备份，返回保存路径；用户取消返回 null。
  Future<String?> saveBackup(String json);

  /// 选择并读取一个备份 JSON 文件内容；用户取消返回 null。
  Future<String?> pickBackupJson();
}

class FilePickerBackupGateway implements BackupFileGateway {
  @override
  Future<String?> saveBackup(String json) async {
    final bytes = Uint8List.fromList(utf8.encode(json));
    final writesInPicker = Platform.isAndroid || Platform.isIOS;
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Settle backup',
      fileName: 'settle_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: writesInPicker ? bytes : null,
    );
    if (path != null && !writesInPicker) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return path;
  }

  @override
  Future<String?> pickBackupJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final bytes = result.files.single.bytes;
    if (bytes == null) return null;
    return utf8.decode(bytes);
  }
}

final backupFileGatewayProvider = Provider<BackupFileGateway>(
  (ref) => FilePickerBackupGateway(),
);
