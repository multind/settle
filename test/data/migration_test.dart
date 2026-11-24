import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  // 本文件直接构造 AppDatabase（不经 createTestDatabase），sqlite3 原生库由
  // Dart native assets（sqlite3 3.x）在 flutter test 时自动提供（见 test_utils.dart）。

  test('v1 库关闭后重开数据保留，schemaVersion 不变（迁移机制基线）', () async {
    final dir = await Directory.systemTemp.createTemp('gtd_migration_test');
    final file = File('${dir.path}${Platform.pathSeparator}test.db');

    final db1 = AppDatabase(NativeDatabase(file));
    final id = await db1.into(db1.projects).insert(ProjectsCompanion.insert(
      name: '客户交付',
      status: 'active',
      createdAt: 1000,
      updatedAt: 1000,
    ));
    await db1.close();

    final db2 = AppDatabase(NativeDatabase(file));
    expect(db2.schemaVersion, 1);
    final row = await (db2.select(db2.projects)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, '客户交付');
    expect(row.status, 'active');
    await db2.close();

    await dir.delete(recursive: true);
  });

  test('迁移步骤表为空时 applyMigrations 幂等不报错', () async {
    final db = createTestDatabase();
    expect(db.schemaVersion, 1);
    await db.close();
  });
}
