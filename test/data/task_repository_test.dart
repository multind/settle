// 仅需 drift 的 Value 用于直插 TasksCompanion；隐藏与 matcher 冲突的 isNull/isNotNull。
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/core/models/task_draft.dart';
import 'package:settle_app/data/repositories/context_repository.dart';
import 'package:settle_app/data/repositories/project_repository.dart';
import 'package:settle_app/data/repositories/tag_repository.dart';
import 'package:settle_app/data/repositories/task_repository.dart';
import 'package:settle_app/data/tables.dart';
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

  // ---- v0.3 数据层：四视图查询边界（规格 §4.1） ----

  // 固定「当前」时刻：边界用例注入时钟，消除跨午夜竞态。
  final fixedNow = DateTime(2026, 11, 25, 10, 0);

  /// [base] 当日 23:59:59.999 的 ms epoch（与 TaskRepository._endOfTodayMs 同口径）。
  int endOfDayMs(DateTime base) =>
      DateTime(base.year, base.month, base.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;

  test('watchToday/Upcoming 边界：今日 23:59:59.999 与明日 00:00 精确命中', () async {
    final fixedRepo = TaskRepository(db, now: () => fixedNow);
    final todayEndMs = endOfDayMs(fixedNow);
    final tomorrowStartMs = todayEndMs + 1; // 明日 00:00:00.000
    final t1 = await fixedRepo.create(TaskDraft(
      title: '今日末 scheduled',
      status: TaskStatus.nextAction,
      scheduled: DateTime.fromMillisecondsSinceEpoch(todayEndMs),
    ));
    final t2 = await fixedRepo.create(TaskDraft(
      title: '今日末 dueDate',
      status: TaskStatus.nextAction,
      dueDate: DateTime.fromMillisecondsSinceEpoch(todayEndMs),
    ));
    final t3 = await fixedRepo.create(TaskDraft(
      title: '明日零时 scheduled',
      status: TaskStatus.nextAction,
      scheduled: DateTime.fromMillisecondsSinceEpoch(tomorrowStartMs),
    ));
    final t4 = await fixedRepo.create(TaskDraft(
      title: '明日零时 dueDate',
      status: TaskStatus.nextAction,
      dueDate: DateTime.fromMillisecondsSinceEpoch(tomorrowStartMs),
    ));

    final todayIds = (await fixedRepo.watchToday().first).map((t) => t.id).toList();
    expect(todayIds, containsAll([t1.id, t2.id]));
    expect(todayIds, isNot(contains(t3.id)));
    expect(todayIds, isNot(contains(t4.id)));

    final upcomingIds =
        (await fixedRepo.watchUpcoming().first).map((t) => t.id).toList();
    expect(upcomingIds, containsAll([t3.id, t4.id]));
    expect(upcomingIds, isNot(contains(t1.id)));
    expect(upcomingIds, isNot(contains(t2.id)));
  });

  test('watchAnytime：无日期任务（规格 §4.1）', () async {
    final t = await repo
        .create(const TaskDraft(title: '随时', status: TaskStatus.nextAction));
    final withDate = await repo.create(TaskDraft(
      title: '有日期',
      status: TaskStatus.nextAction,
      scheduled: DateTime(2026, 12, 31),
    ));
    final anytime = await repo.watchAnytime().first;
    expect(anytime.map((t) => t.id).toList(), [t.id]);
    expect(anytime.map((t) => t.id), isNot(contains(withDate.id)));
  });

  test('边界混合：scheduled=今天 + dueDate=明天 → Today/Upcoming 双命中（spec OR 语义）',
      () async {
    final fixedRepo = TaskRepository(db, now: () => fixedNow);
    final todayEndMs = endOfDayMs(fixedNow);
    final t = await fixedRepo.create(TaskDraft(
      title: '跨日任务',
      status: TaskStatus.nextAction,
      scheduled: DateTime.fromMillisecondsSinceEpoch(todayEndMs),
      dueDate: DateTime.fromMillisecondsSinceEpoch(todayEndMs + 1),
    ));
    expect((await fixedRepo.watchToday().first).map((x) => x.id), [t.id]);
    expect((await fixedRepo.watchUpcoming().first).map((x) => x.id), [t.id]);
    expect(await fixedRepo.watchAnytime().first, isEmpty);
  });

  test('waiting/done 不进三个 next_action 视图；watchDone 只含 done（规格 §4.1）',
      () async {
    final waiting = await repo.create(TaskDraft(
      title: '等待中',
      status: TaskStatus.waiting,
      waitingOn: '财务部',
      scheduled: DateTime(2026, 11, 25),
    ));
    final done = await repo.create(TaskDraft(
      title: '已完成',
      status: TaskStatus.nextAction,
      scheduled: DateTime(2026, 11, 25),
    ));
    await repo.complete(done.id);
    expect(await repo.watchToday().first, isEmpty);
    expect(await repo.watchUpcoming().first, isEmpty);
    expect(await repo.watchAnytime().first, isEmpty);
    final doneList = await repo.watchDone().first;
    expect(doneList.map((t) => t.id).toList(), [done.id]);
    expect(doneList.map((t) => t.id), isNot(contains(waiting.id)));
  });

  test('watchDone 排序：completedAt desc、null 最后（规格 §4.1）', () async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    // 手工直插 done 任务（completedAt=null 无法经 complete/setStatus 构造，
    // 二者都会写 now）：一个有 completedAt、一个 null，断言顺序。
    final nullDone = await db.into(db.tasks).insert(TasksCompanion.insert(
          title: 'null 完成时间',
          status: TaskStatus.done.storage,
          createdAt: nowMs,
          updatedAt: nowMs,
        ));
    final early = await db.into(db.tasks).insert(TasksCompanion.insert(
          title: '完成时间早',
          status: TaskStatus.done.storage,
          completedAt: const Value(1000),
          createdAt: nowMs,
          updatedAt: nowMs,
        ));
    final late = await db.into(db.tasks).insert(TasksCompanion.insert(
          title: '完成时间晚',
          status: TaskStatus.done.storage,
          completedAt: const Value(3000),
          createdAt: nowMs,
          updatedAt: nowMs,
        ));
    final list = await repo.watchDone().first;
    expect(list.map((t) => t.id).toList(), [late, early, nullDone]);
  });

  // ---- v0.3 数据层：completedAt 流转（规格 §4.2） ----

  test('complete 写 completedAt、reopen 清空、非 done 状态清空（规格 §4.2）', () async {
    final t = await repo
        .create(const TaskDraft(title: '无重复任务', status: TaskStatus.nextAction));
    await repo.complete(t.id);
    var row = (await repo.byId(t.id))!;
    expect(row.status, TaskStatus.done.storage);
    expect(row.completedAt, isNotNull);

    await repo.reopen(t.id);
    row = (await repo.byId(t.id))!;
    expect(row.status, TaskStatus.nextAction.storage);
    expect(row.completedAt, isNull);

    await repo.complete(t.id);
    expect((await repo.byId(t.id))!.completedAt, isNotNull);
    await repo.setStatus(t.id, TaskStatus.someday);
    row = (await repo.byId(t.id))!;
    expect(row.status, TaskStatus.someday.storage);
    expect(row.completedAt, isNull);
  });

  // ---- v0.3 数据层：reorder / setScheduled（规格 §4.2） ----

  test('reorder 持久化：重排后 watchByStatus 顺序变化（规格 §4.2）', () async {
    final a = await repo
        .create(const TaskDraft(title: 'a', status: TaskStatus.nextAction));
    final b = await repo
        .create(const TaskDraft(title: 'b', status: TaskStatus.nextAction));
    final c = await repo
        .create(const TaskDraft(title: 'c', status: TaskStatus.nextAction));
    expect(
        (await repo.watchByStatus(TaskStatus.nextAction).first)
            .map((t) => t.id)
            .toList(),
        [a.id, b.id, c.id]);
    await repo.reorder([c.id, b.id, a.id]);
    expect(
        (await repo.watchByStatus(TaskStatus.nextAction).first)
            .map((t) => t.id)
            .toList(),
        [c.id, b.id, a.id]);
  });

  test('setScheduled 写/清 scheduled（规格 §4.2）', () async {
    final t = await repo
        .create(const TaskDraft(title: '待调度', status: TaskStatus.nextAction));
    expect((await repo.byId(t.id))!.scheduled, isNull);
    final date = DateTime(2026, 12, 1);
    await repo.setScheduled(t.id, date);
    expect((await repo.byId(t.id))!.scheduled, date.millisecondsSinceEpoch);
    await repo.setScheduled(t.id, null);
    expect((await repo.byId(t.id))!.scheduled, isNull);
  });

  // ---- v0.3 数据层：重复生成（规格 §4.4） ----

  test('重复生成 weekly：原任务 done + 副本 +7 天、字段/标签克隆（规格 §4.4）',
      () async {
    final p = await projects.create(name: '客户交付');
    final c = await contexts.create(name: '@电脑');
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    final base = DateTime(2026, 11, 25, 10, 0);
    final t = await repo.create(TaskDraft(
      title: '每周例会',
      notes: '准备议程',
      status: TaskStatus.nextAction,
      scheduled: base,
      dueDate: base,
      reminderAt: DateTime(2026, 11, 25, 9, 0),
      energy: EnergyLevel.medium,
      priority: PriorityLevel.high,
      projectId: p.id,
      contextId: c.id,
      tagIds: {tag.id},
      repeatRule: 'weekly',
    ));
    await repo.complete(t.id);

    final original = (await repo.byId(t.id))!;
    expect(original.status, TaskStatus.done.storage);
    expect(original.completedAt, isNotNull);
    expect(original.repeatRule, 'weekly');

    final clones = await repo.watchByStatus(TaskStatus.nextAction).first;
    expect(clones, hasLength(1));
    final clone = clones.single;
    expect(clone.title, '每周例会');
    expect(clone.notes, '准备议程');
    expect(clone.status, TaskStatus.nextAction.storage);
    expect(
        clone.scheduled,
        DateTime(2026, 11, 25 + 7, 10, 0).millisecondsSinceEpoch);
    expect(
        clone.dueDate,
        DateTime(2026, 11, 25 + 7, 10, 0).millisecondsSinceEpoch);
    expect(
        clone.reminderAt,
        DateTime(2026, 11, 25 + 7, 9, 0).millisecondsSinceEpoch);
    expect(clone.energy, EnergyLevel.medium.storage);
    expect(clone.priority, PriorityLevel.high.storage);
    expect(clone.projectId, p.id);
    expect(clone.contextId, c.id);
    expect(clone.repeatRule, 'weekly');
    expect(clone.completedAt, isNull);
    expect(clone.waitingOn, isNull);
    expect(clone.sortOrder, original.sortOrder + 1);
    final bound = await repo.watchTags(clone.id).first;
    expect(bound.map((x) => x.id).toList(), [tag.id]);
    expect(await db.select(db.tasks).get(), hasLength(2));
  });

  test('重复生成 every:3：副本 +3 天（规格 §4.4）', () async {
    final base = DateTime(2026, 11, 25, 9, 30);
    final t = await repo.create(TaskDraft(
      title: '每三天',
      status: TaskStatus.nextAction,
      scheduled: base,
      repeatRule: 'every:3',
    ));
    await repo.complete(t.id);
    final clone = (await repo.watchByStatus(TaskStatus.nextAction).first).single;
    expect(
        clone.scheduled,
        DateTime(2026, 11, 25 + 3, 9, 30).millisecondsSinceEpoch);
    expect(clone.repeatRule, 'every:3');
    expect(await db.select(db.tasks).get(), hasLength(2));
  });

  test('重复生成 monthly 月末钳制：1/31 → 2/28（非闰年）（规格 §4.4）', () async {
    // 2027 非闰年：2 月 28 天。
    final t = await repo.create(TaskDraft(
      title: '每月末',
      status: TaskStatus.nextAction,
      dueDate: DateTime(2027, 1, 31),
      repeatRule: 'monthly',
    ));
    await repo.complete(t.id);
    final clone = (await repo.watchByStatus(TaskStatus.nextAction).first).single;
    expect(clone.dueDate, DateTime(2027, 2, 28).millisecondsSinceEpoch);
    expect(await db.select(db.tasks).get(), hasLength(2));
  });

  test('幂等回归：对已 done 的重复任务再次 complete 不产生新副本（规格 §4.4）',
      () async {
    final t = await repo.create(TaskDraft(
      title: '重复任务',
      status: TaskStatus.nextAction,
      scheduled: DateTime(2026, 11, 25, 8, 0),
      repeatRule: 'weekly',
    ));
    await repo.complete(t.id);
    expect(await db.select(db.tasks).get(), hasLength(2));
    // 再次 complete 原任务（已 done）：幂等守卫直接返回，总数不变。
    await repo.complete(t.id);
    expect(await db.select(db.tasks).get(), hasLength(2));
  });

  // ---- v0.3 数据层：无效重复规则（规格 §4.3） ----

  test('无效重复规则（EVERY:3 大小写 / unknown）→ complete 不生成副本（规格 §4.3）',
      () async {
    final upper = await repo.create(TaskDraft(
      title: '大写规则',
      status: TaskStatus.nextAction,
      scheduled: DateTime(2026, 11, 25),
      repeatRule: 'EVERY:3',
    ));
    await repo.complete(upper.id);
    expect(await db.select(db.tasks).get(), hasLength(1));

    final unknown = await repo.create(TaskDraft(
      title: '未知规则',
      status: TaskStatus.nextAction,
      scheduled: DateTime(2026, 11, 26),
      repeatRule: 'unknown',
    ));
    await repo.complete(unknown.id);
    expect(await db.select(db.tasks).get(), hasLength(2));
  });
}
