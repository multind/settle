import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late TagRepository repo;
  late TaskRepository tasks;
  setUp(() {
    db = createTestDatabase();
    repo = TagRepository(db);
    tasks = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('create 保存名称与颜色', () async {
    final t = await repo.create(name: '客户', color: '#1A73E8');
    expect(t.name, '客户');
    expect(t.color, '#1A73E8');
  });

  test('同名标签被唯一约束拒绝', () async {
    await repo.create(name: '客户', color: '#1A73E8');
    expect(() => repo.create(name: '客户', color: '#FF0000'), throwsA(isA<SqliteException>()));
  });

  test('update 修改名称与颜色', () async {
    final t = await repo.create(name: '客户', color: '#1A73E8');
    await repo.update(t.id, name: '重点客户', color: '#FF0000');
    final after = await repo.byId(t.id);
    expect(after!.name, '重点客户');
    expect(after.color, '#FF0000');
  });

  test('delete 从所有 Task 解绑（规格 §5.2）', () async {
    final tag = await repo.create(name: '客户', color: '#1A73E8');
    final t = await tasks.create(TaskDraft(title: '写方案', tagIds: {tag.id}));
    final bound = await db.select(db.taskTags).get();
    expect(bound, hasLength(1));
    await repo.delete(tag.id);
    expect(await db.select(db.tags).get(), isEmpty);
    expect(await db.select(db.taskTags).get(), isEmpty);
    expect(await db.select(db.tasks).get(), hasLength(1)); // Task 本身保留
  });
}
