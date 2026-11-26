import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/core/models/clarify_decision.dart';
import 'package:settle_app/core/models/task_draft.dart';
import 'package:settle_app/core/workflow/clarify_service.dart';
import 'package:settle_app/data/repositories/inbox_repository.dart';
import 'package:settle_app/data/repositories/project_repository.dart';
import 'package:settle_app/data/repositories/task_repository.dart';
import 'package:settle_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ClarifyService service;
  late InboxRepository inbox;
  late TaskRepository tasks;
  late ProjectRepository projects;
  late InboxItem item;

  setUp(() {
    db = createTestDatabase();
    inbox = InboxRepository(db);
    tasks = TaskRepository(db);
    projects = ProjectRepository(db);
    service = ClarifyService(db, inbox, tasks, projects);
  });
  tearDown(() => db.close());

  Future<void> seedItem() async {
    item = await inbox.add(rawText: '写周报', source: TaskSource.text);
  }

  test('转 Task（下一步）：条目标 clarified 且创建 Task（规格 §5.2 路径①）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToTask(TaskDraft(title: '写周报')));
    expect((await inbox.byId(item.id))!.status, 'clarified');
    final rows = await db.select(db.tasks).get();
    expect(rows, hasLength(1));
    expect(rows.single.title, '写周报');
    expect(rows.single.status, 'next_action');
  });

  test('转 Task（等待）：创建 waiting 任务并带 waitingOn（路径②）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToTask(TaskDraft(
      title: '跟进报销',
      status: TaskStatus.waiting,
      waitingOn: '财务部',
    )));
    final row = (await db.select(db.tasks).get()).single;
    expect(row.status, 'waiting');
    expect(row.waitingOn, '财务部');
    expect((await inbox.byId(item.id))!.status, 'clarified');
  });

  test('转 Task（将来也许）：创建 someday 任务（路径③）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToTask(TaskDraft(title: '学做饭', status: TaskStatus.someday)));
    expect((await db.select(db.tasks).get()).single.status, 'someday');
  });

  test('转 Project（active）并标 clarified（路径④）', () async {
    await seedItem();
    await service.clarify(item, ClarifyToProject(name: '客户交付', goal: '完成季度交付'));
    final p = (await db.select(db.projects).get()).single;
    expect(p.name, '客户交付');
    expect(p.goal, '完成季度交付');
    expect(p.status, 'active');
    expect((await inbox.byId(item.id))!.status, 'clarified');
  });

  test('删除：条目硬删除且不产生 Task/Project（路径⑥）', () async {
    await seedItem();
    await service.clarify(item, ClarifyDelete());
    expect(await inbox.byId(item.id), isNull);
    expect(await db.select(db.tasks).get(), isEmpty);
    expect(await db.select(db.projects).get(), isEmpty);
  });

  test('waiting 决策缺 waitingOn 抛 ArgumentError 且不标 clarified', () async {
    await seedItem();
    expect(
      () => service.clarify(item, ClarifyToTask(TaskDraft(title: 'x', status: TaskStatus.waiting))),
      throwsArgumentError,
    );
    expect((await inbox.byId(item.id))!.status, 'pending');
  });
}
