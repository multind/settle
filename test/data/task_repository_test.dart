import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;
  late ProjectRepository projects;
  late ContextRepository contexts;
  late TagRepository tags;
  setUp(() {
    db = createTestDatabase();
    repo = TaskRepository(db);
    projects = ProjectRepository(db);
    contexts = ContextRepository(db);
    tags = TagRepository(db);
  });
  tearDown(() => db.close());

  test('create 全字段落库（规格 §5.1）', () async {
    final p = await projects.create(name: '客户交付');
    final c = await contexts.create(name: '@电脑');
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    final due = DateTime(2026, 11, 30);
    final task = await repo.create(TaskDraft(
      title: '写周报',
      notes: '先整理数据',
      status: TaskStatus.nextAction,
      dueDate: due,
      scheduled: due,
      energy: EnergyLevel.medium,
      priority: PriorityLevel.high,
      projectId: p.id,
      contextId: c.id,
      tagIds: {tag.id},
    ));
    expect(task.title, '写周报');
    expect(task.notes, '先整理数据');
    expect(task.status, 'next_action');
    expect(task.dueDate, due.millisecondsSinceEpoch);
    expect(task.scheduled, due.millisecondsSinceEpoch);
    expect(task.energy, 'medium');
    expect(task.priority, 'high');
    expect(task.projectId, p.id);
    expect(task.contextId, c.id);
    final bound = await repo.watchTags(task.id).first;
    expect(bound.map((t) => t.id).toList(), [tag.id]);
  });

  test('waiting 必须带 waitingOn，否则 ArgumentError（规格 §5.2）', () async {
    expect(() => repo.create(TaskDraft(title: 'x', status: TaskStatus.waiting)),
        throwsArgumentError);
    expect(
        () => repo.setStatus(0, TaskStatus.waiting), // id 不存在，先验约束
        throwsArgumentError);
  });

  test('状态流转：next_action→waiting→done→next_action（规格 §5.2）', () async {
    final t = await repo.create(TaskDraft(title: '跟进报销', status: TaskStatus.nextAction));
    await repo.setStatus(t.id, TaskStatus.waiting, waitingOn: '财务部');
    var row = (await repo.byId(t.id))!;
    expect(row.status, 'waiting');
    expect(row.waitingOn, '财务部');
    await repo.complete(t.id);
    row = (await repo.byId(t.id))!;
    expect(row.status, 'done');
    expect(row.waitingOn, isNull); // 离开 waiting 即清空
    await repo.reopen(t.id);
    expect((await repo.byId(t.id))!.status, 'next_action');
  });

  test('update 全字段覆盖并重建标签绑定', () async {
    final t = await repo.create(TaskDraft(title: '旧', status: TaskStatus.nextAction));
    final tagA = await tags.create(name: 'A', color: '#111111');
    final tagB = await tags.create(name: 'B', color: '#222222');
    await repo.update(t.id, TaskDraft(
      title: '新',
      status: TaskStatus.someday,
      priority: PriorityLevel.low,
      tagIds: {tagB.id},
    ));
    final row = (await repo.byId(t.id))!;
    expect(row.title, '新');
    expect(row.status, 'someday');
    expect(row.priority, 'low');
    final bound = await repo.watchTags(t.id).first;
    expect(bound.map((x) => x.id).toList(), [tagB.id]);
  });

  test('setProject / setContext 单独更新', () async {
    final t = await repo.create(TaskDraft(title: 'x', status: TaskStatus.nextAction));
    final p = await projects.create(name: 'P');
    final c = await contexts.create(name: '@外出');
    await repo.setProject(t.id, p.id);
    await repo.setContext(t.id, c.id);
    final row = (await repo.byId(t.id))!;
    expect(row.projectId, p.id);
    expect(row.contextId, c.id);
  });

  test('addTag / removeTag 维护绑定', () async {
    final t = await repo.create(TaskDraft(title: 'x', status: TaskStatus.nextAction));
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    await repo.addTag(t.id, tag.id);
    expect((await repo.watchTags(t.id).first), hasLength(1));
    await repo.removeTag(t.id, tag.id);
    expect((await repo.watchTags(t.id).first), isEmpty);
  });

  test('delete 硬删除并清理绑定', () async {
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    final t = await repo.create(TaskDraft(title: 'x', status: TaskStatus.nextAction, tagIds: {tag.id}));
    await repo.delete(t.id);
    expect(await repo.byId(t.id), isNull);
    expect(await db.select(db.taskTags).get(), isEmpty);
  });

  test('watchByStatus / watchByProject / watchByContext 过滤', () async {
    final p = await projects.create(name: 'P');
    final c = await contexts.create(name: '@电脑');
    await repo.create(TaskDraft(title: 'a', status: TaskStatus.nextAction));
    await repo.create(TaskDraft(title: 'b', status: TaskStatus.waiting, waitingOn: 'x', projectId: p.id, contextId: c.id));
    expect(await repo.watchByStatus(TaskStatus.waiting).first, hasLength(1));
    expect(await repo.watchByProject(p.id).first, hasLength(1));
    expect(await repo.watchByContext(c.id).first, hasLength(1));
    expect(await repo.watchByStatus(TaskStatus.someday).first, isEmpty);
  });
}
