import 'package:drift/native.dart';
import 'package:settle_app/data/tables.dart';

/// 测试用内存数据库。
///
/// sqlite3 原生库由 Dart native assets（sqlite3 3.x）在 flutter test 时自动
/// 提供，无需再手动加载 tool/windows/sqlite3.dll。
AppDatabase createTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}
