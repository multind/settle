import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = createTestDatabase());
  tearDown(() => db.close());

  test('schemaVersion 为 1（迁移机制基线）', () {
    expect(db.schemaVersion, 1);
  });

  test('首次创建自动播种三个默认情境', () async {
    final contexts = await db.select(db.contexts).get();
    expect(contexts.map((c) => c.name).toList(), ['@电脑', '@外出', '@电话']);
  });

  test('tags.name 唯一约束生效', () async {
    await db.into(db.tags).insert(TagsCompanion.insert(name: '报告', color: '#1A73E8'));
    expect(
      () => db.into(db.tags).insert(TagsCompanion.insert(name: '报告', color: '#FF0000')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('tasks 表四个索引存在（规格 §5.1）', () async {
    final rows = await db
        .customSelect(
            "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='tasks'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(names, containsAll(
        ['idx_tasks_project', 'idx_tasks_context', 'idx_tasks_status', 'idx_tasks_due_date']));
  });

  test('插入 InboxItem 后可按 id 读回', () async {
    final id = await db.into(db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: '写周报',
      source: 'text',
      status: 'pending',
      createdAt: 1,
      updatedAt: 1,
    ));
    final row = await (db.select(db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(row.rawText, '写周报');
    expect(row.status, 'pending');
  });
}
