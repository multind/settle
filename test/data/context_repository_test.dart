import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/models/task_draft.dart';
import 'package:settle_app/data/repositories/context_repository.dart';
import 'package:settle_app/data/repositories/task_repository.dart';
import 'package:settle_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ContextRepository repo;
  late TaskRepository tasks;
  setUp(() async {
    db = createTestDatabase();
    repo = ContextRepository(db);
    tasks = TaskRepository(db);
    // onCreate 会种子化默认情境（@电脑/@外出/@电话），先清空使每个测试从空表开始。
    await db.delete(db.contexts).go();
  });
  tearDown(() => db.close());

  test('create 保存名称与图标', () async {
    final c = await repo.create(name: '@外出', icon: 'directions_walk');
    expect(c.name, '@外出');
    expect(c.icon, 'directions_walk');
  });

  test('update 修改名称/图标/排序', () async {
    final c = await repo.create(name: '@外出');
    await repo.update(c.id, name: '@车程', icon: 'directions_car', sort: 5);
    final updated = await repo.byId(c.id);
    expect(updated!.name, '@车程');
    expect(updated.icon, 'directions_car');
    expect(updated.sort, 5);
  });

  test('delete 后关联 Task 的 context_id 置空（规格 §5.2）', () async {
    final c = await repo.create(name: '@电话');
    final t = await tasks.create(TaskDraft(title: '打电话', contextId: c.id));
    expect(t.contextId, c.id);
    await repo.delete(c.id);
    expect(await db.select(db.contexts).get(), isEmpty);
    final after = await (db.select(db.tasks)..where((r) => r.id.equals(t.id))).getSingle();
    expect(after.contextId, isNull);
  });

  test('delete 无关联任务的情境', () async {
    final c = await repo.create(name: '@电脑');
    await repo.delete(c.id);
    expect(await db.select(db.contexts).get(), isEmpty);
  });
}
