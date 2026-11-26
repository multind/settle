import 'dart:io';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:settle_app/data/tables.dart';

/// 应用运行时的数据库连接（文件持久化）。
Future<AppDatabase> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}gtd_app.db');
  return AppDatabase(NativeDatabase(file));
}
