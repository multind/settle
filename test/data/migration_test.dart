import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
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
    expect(db2.schemaVersion, 2);
    final row =
        await (db2.select(db2.projects)..where((t) => t.id.equals(id))).getSingle();
    expect(row.name, '客户交付');
    expect(row.status, 'active');
    await db2.close();

    await dir.delete(recursive: true);
  });

  test('全新内存库打开正常，schemaVersion 为 2（迁移步骤注册表非空）', () async {
    final db = createTestDatabase();
    expect(db.schemaVersion, 2);
    await db.close();
  });

  test('v1 库（旧版 tasks 表）打开触发 v1→v2 迁移：4 新列 + sortOrder 回填 + 数据保留', () async {
    final dir = await Directory.systemTemp.createTemp('gtd_migration_test');
    final file = File('${dir.path}${Platform.pathSeparator}test.db');

    // 用禁用迁移的连接手写 v1 schema（避免触发 onCreate/onUpgrade）。
    // 列名以 lib/data/tables.g.dart 的 GeneratedColumn 定义为准（snake_case）。
    final raw = AppDatabase(NativeDatabase(file, enableMigrations: false));
    await raw.customStatement('''
      CREATE TABLE tasks (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        notes TEXT,
        status TEXT NOT NULL,
        due_date INTEGER,
        scheduled INTEGER,
        energy TEXT,
        priority TEXT,
        waiting_on TEXT,
        project_id INTEGER REFERENCES projects (id),
        context_id INTEGER REFERENCES contexts (id),
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await raw.customStatement('''
      INSERT INTO tasks (title, status, created_at, updated_at)
      VALUES ('旧任务', 'next_action', 1000, 1000);
    ''');
    await raw.customStatement('PRAGMA user_version = 1;');
    await raw.close();

    // 重新打开（迁移启用）：user_version 1 < schemaVersion 2，触发 onUpgrade。
    final db = AppDatabase(NativeDatabase(file));
    expect(db.schemaVersion, 2);

    // 4 新列存在。
    final tableInfo = await db.customSelect('PRAGMA table_info(tasks)').get();
    final columns = tableInfo.map((r) => r.read<String>('name')).toSet();
    expect(
      columns,
      containsAll(['completed_at', 'sort_order', 'repeat_rule', 'reminder_at']),
    );

    // 原数据不丢，回填 sortOrder == id，新字段默认为 null。
    final row = await (db.select(db.tasks)).getSingle();
    expect(row.title, '旧任务');
    expect(row.status, 'next_action');
    expect(row.sortOrder, row.id);
    expect(row.completedAt, isNull);
    expect(row.repeatRule, isNull);
    expect(row.reminderAt, isNull);

    // 新列可经由 ORM 正常写入（迁移列名与生成 schema 一致）。
    await (db.update(db.tasks)..where((t) => t.id.equals(row.id)))
        .write(const TasksCompanion(sortOrder: Value(7)));
    final updated = await (db.select(db.tasks)).getSingle();
    expect(updated.sortOrder, 7);

    await db.close();
    await dir.delete(recursive: true);
  });
}
