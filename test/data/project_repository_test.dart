import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository repo;
  late TaskRepository tasks;
  setUp(() {
    db = createTestDatabase();
    repo = ProjectRepository(db);
    tasks = TaskRepository(db);
  });
  tearDown(() => db.close());

  test('create 默认 active 并带时间戳', () async {
    final p = await repo.create(name: '客户交付');
    expect(p.name, '客户交付');
    expect(p.status, 'active');
    expect(p.createdAt, greaterThan(0));
  });

  test('updateNameAndGoal 修改', () async {
    final p = await repo.create(name: 'A', goal: 'g1');
    await repo.updateNameAndGoal(p.id, name: 'B', goal: 'g2');
    expect((await repo.byId(p.id))!.name, 'B');
    expect((await repo.byId(p.id))!.goal, 'g2');
  });

  test('setStatus 流转 active→done→someday', () async {
    final p = await repo.create(name: 'A');
    await repo.setStatus(p.id, ProjectStatus.done);
    expect((await repo.byId(p.id))!.status, 'done');
    await repo.setStatus(p.id, ProjectStatus.someday);
    expect((await repo.byId(p.id))!.status, 'someday');
  });

  test('delete 级联删除其下 Task（规格 §5.2）', () async {
    final p = await repo.create(name: '客户交付');
    final t = await tasks.create(TaskDraft(title: '写初稿', projectId: p.id));
    expect(t.projectId, p.id);
    await repo.delete(p.id);
    expect(await db.select(db.projects).get(), isEmpty);
    expect(await db.select(db.tasks).get(), isEmpty);
  });

  test('delete 不影响无任务项目', () async {
    final p = await repo.create(name: '空项目');
    await repo.delete(p.id);
    expect(await db.select(db.projects).get(), isEmpty);
  });

  test('watchAll 推送全部项目', () async {
    await repo.create(name: 'A');
    final rows = await repo.watchAll().first;
    expect(rows, hasLength(1));
  });
}
