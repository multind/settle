import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/repeat_rule.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/tables.dart';

class TaskRepository {
  /// [now] 为可注入时钟（测试用固定时刻消除跨午夜竞态）；缺省用 `DateTime.now`。
  TaskRepository(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;
  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<List<Task>> watchAll() =>
      (_db.select(_db.tasks)..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Stream<List<Task>> watchByStatus(TaskStatus status) =>
      (_db.select(_db.tasks)..where((t) => t.status.equals(status.storage))..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Stream<List<Task>> watchByProject(int projectId) =>
      (_db.select(_db.tasks)..where((t) => t.projectId.equals(projectId))..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Stream<List<Task>> watchByContext(int contextId) =>
      (_db.select(_db.tasks)..where((t) => t.contextId.equals(contextId))..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// 今日：`next_action` 且 `scheduled` 或 `dueDate` ≤ 今日 23:59:59.999。
  Stream<List<Task>> watchToday() {
    final endOfToday = _endOfTodayMs();
    return (_db.select(_db.tasks)
          ..where((t) =>
              t.status.equals(TaskStatus.nextAction.storage) &
              (t.scheduled.isSmallerOrEqualValue(endOfToday) |
                  t.dueDate.isSmallerOrEqualValue(endOfToday)))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  /// 随时：`next_action` 且 `scheduled` 与 `dueDate` 均为 null。
  Stream<List<Task>> watchAnytime() =>
      (_db.select(_db.tasks)
            ..where((t) =>
                t.status.equals(TaskStatus.nextAction.storage) &
                t.scheduled.isNull() &
                t.dueDate.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  /// 即将：`next_action` 且 `scheduled` 或 `dueDate` > 今日 23:59:59.999。
  Stream<List<Task>> watchUpcoming() {
    final endOfToday = _endOfTodayMs();
    return (_db.select(_db.tasks)
          ..where((t) =>
              t.status.equals(TaskStatus.nextAction.storage) &
              (t.scheduled.isBiggerThanValue(endOfToday) |
                  t.dueDate.isBiggerThanValue(endOfToday)))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  /// 已完成：`done`，按 `completedAt` 降序（null 最后）再 `id` 降序。
  Stream<List<Task>> watchDone() =>
      (_db.select(_db.tasks)
            ..where((t) => t.status.equals(TaskStatus.done.storage))
            ..orderBy([
              (t) => OrderingTerm.desc(t.completedAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  /// 到点提醒的一次性查询（v0.3 调度 §4.2 轮询窗口）：
  /// `since < reminderAt <= now`（严格大于上一轮、小于等于当前轮，边界精确命中）
  /// 且未完成，按 `reminderAt` 升序。NULL reminderAt 经 SQL 比较天然排除。
  Future<List<Task>> dueReminders({required int since, required int now}) =>
      (_db.select(_db.tasks)
            ..where((t) =>
                t.reminderAt.isBiggerThanValue(since) &
                t.reminderAt.isSmallerOrEqualValue(now) &
                t.status.equals(TaskStatus.done.storage).not())
            ..orderBy([(t) => OrderingTerm.asc(t.reminderAt)]))
          .get();

  Future<List<Task>> getAll() async => _db.select(_db.tasks).get();

  Future<Task?> byId(int id) async =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Task> create(TaskDraft draft) async {
    _assertWaitingOn(draft);
    final id = await _insertTask(draft);
    // 回填 sortOrder = id（与旧 id 序等价）；仅 create 保留该回填。
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(sortOrder: Value(id)));
    return (await byId(id))!;
  }

  /// 插入 + 绑标签的内部助手（create 与 complete 的重复副本共用）。
  /// 返回新任务 id；不负责 sortOrder 回填——create 单独回填 = id，
  /// 重复副本在 complete 事务内设为 max+1。
  Future<int> _insertTask(TaskDraft draft) async {
    final now = _now().millisecondsSinceEpoch;
    final id = await _db.into(_db.tasks).insert(TasksCompanion.insert(
      title: draft.title,
      notes: Value(draft.notes),
      status: draft.status.storage,
      dueDate: Value(draft.dueDate?.millisecondsSinceEpoch),
      scheduled: Value(draft.scheduled?.millisecondsSinceEpoch),
      energy: Value(draft.energy?.storage),
      priority: Value(draft.priority?.storage),
      waitingOn: Value(draft.waitingOn),
      projectId: Value(draft.projectId),
      contextId: Value(draft.contextId),
      repeatRule: Value(draft.repeatRule),
      reminderAt: Value(draft.reminderAt?.millisecondsSinceEpoch),
      createdAt: now,
      updatedAt: now,
    ));
    for (final tagId in draft.tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: tagId));
    }
    return id;
  }

  Future<void> update(int id, TaskDraft draft) async {
    _assertWaitingOn(draft);
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      title: Value(draft.title),
      notes: Value(draft.notes),
      status: Value(draft.status.storage),
      dueDate: Value(draft.dueDate?.millisecondsSinceEpoch),
      scheduled: Value(draft.scheduled?.millisecondsSinceEpoch),
      energy: Value(draft.energy?.storage),
      priority: Value(draft.priority?.storage),
      waitingOn: Value(draft.waitingOn),
      projectId: Value(draft.projectId),
      contextId: Value(draft.contextId),
      repeatRule: Value(draft.repeatRule),
      reminderAt: Value(draft.reminderAt?.millisecondsSinceEpoch),
      updatedAt: Value(_now().millisecondsSinceEpoch),
    ));
    await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(id))).go();
    for (final tagId in draft.tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: tagId));
    }
  }

  /// 状态流转（规格 §5.2）：waiting 必须携带 waitingOn；离开 waiting 清空 waitingOn。
  Future<void> setStatus(int id, TaskStatus status, {String? waitingOn}) async {
    if (status == TaskStatus.waiting &&
        (waitingOn == null || waitingOn.trim().isEmpty)) {
      throw ArgumentError('waiting_on is required for waiting tasks');
    }
    final now = _now().millisecondsSinceEpoch;
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      status: Value(status.storage),
      waitingOn: Value(status == TaskStatus.waiting ? waitingOn : null),
      // 完成写时间戳；非 done（重开/改状态）清空，避免残留完成时间。
      completedAt: Value(status == TaskStatus.done ? now : null),
      updatedAt: Value(now),
    ));
  }

  /// 完成：事务内原任务 → done + completedAt=now；若带重复规则（§4.4），
  /// 同一事务内克隆新副本：title/notes/project/context/tags/energy/priority
  /// 原值，status=nextAction，scheduled/dueDate/reminderAt 各按规则推进
  /// （有则推，无则 null），repeatRule 保留，waitingOn=null，
  /// sortOrder = MAX(sortOrder)+1（落到列表末尾）。
  /// 无重复规则时行为与 setStatus(id, done) 完全一致。
  Future<void> complete(int id) async {
    await _db.transaction(() async {
      final task = await byId(id);
      // 幂等守卫：任务不存在或已是 done 时直接返回——不克隆、不重复写，
      // 避免对已 done 的重复任务再次 complete 生成多余副本（双击/重试防护）。
      if (task == null || task.status == TaskStatus.done.storage) return;
      // 原任务写 done + completedAt=now（复用 setStatus，含离开 waiting 清 waitingOn）。
      await setStatus(id, TaskStatus.done);
      final rule = RepeatRule.parse(task.repeatRule);
      if (rule == null) return;
      // 事务内直接查 taskTags 取标签 id 列表。
      final tagIds = (await (_db.select(_db.taskTags)..where((t) => t.taskId.equals(id))).get())
          .map((r) => r.tagId)
          .toSet();
      final clone = TaskDraft(
        title: task.title,
        notes: task.notes,
        status: TaskStatus.nextAction,
        scheduled: task.scheduled == null
            ? null
            : rule.nextDate(DateTime.fromMillisecondsSinceEpoch(task.scheduled!)),
        dueDate: task.dueDate == null
            ? null
            : rule.nextDate(DateTime.fromMillisecondsSinceEpoch(task.dueDate!)),
        energy: EnergyLevel.fromStorageOrNull(task.energy),
        priority: PriorityLevel.fromStorageOrNull(task.priority),
        projectId: task.projectId,
        contextId: task.contextId,
        repeatRule: task.repeatRule,
        reminderAt: task.reminderAt == null
            ? null
            : rule.nextDate(DateTime.fromMillisecondsSinceEpoch(task.reminderAt!)),
        tagIds: tagIds,
      );
      final newId = await _insertTask(clone);
      // 新副本 sortOrder = 当前最大 sortOrder + 1（事务内先查 max 再 UPDATE）。
      final maxExpr = _db.tasks.sortOrder.max();
      final maxRow = await (_db.selectOnly(_db.tasks)..addColumns([maxExpr])).getSingle();
      final maxSortOrder = maxRow.read(maxExpr) ?? 0;
      await (_db.update(_db.tasks)..where((t) => t.id.equals(newId)))
          .write(TasksCompanion(sortOrder: Value(maxSortOrder + 1)));
    });
  }

  Future<void> reopen(int id) => setStatus(id, TaskStatus.nextAction);

  /// 重排的唯一落库入口：按 [orderedIds] 顺序逐 id 写 `sortOrder = index`。
  Future<void> reorder(List<int> orderedIds) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(orderedIds[i])))
            .write(TasksCompanion(sortOrder: Value(i)));
      }
    });
  }

  /// 设置调度时间（ms epoch），null 表示清除；同时刷新 updatedAt。
  Future<void> setScheduled(int id, DateTime? date) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      scheduled: Value(date?.millisecondsSinceEpoch),
      updatedAt: Value(_now().millisecondsSinceEpoch),
    ));
  }

  /// 设置截止时间（ms epoch），null 表示清除；同时刷新 updatedAt。
  /// 与 [setScheduled] 同款单列更新（批量设日期用；经 update/TaskDraft 会重写
  /// 全字段并重建 tag 绑定，不适用于仅改截止日的批量场景）。
  Future<void> setDueDate(int id, DateTime? date) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      dueDate: Value(date?.millisecondsSinceEpoch),
      updatedAt: Value(_now().millisecondsSinceEpoch),
    ));
  }

  Future<void> setProject(int id, int? projectId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      projectId: Value(projectId),
      updatedAt: Value(_now().millisecondsSinceEpoch),
    ));
  }

  Future<void> setContext(int id, int? contextId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      contextId: Value(contextId),
      updatedAt: Value(_now().millisecondsSinceEpoch),
    ));
  }

  Future<void> addTag(int taskId, int tagId) async {
    await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: taskId, tagId: tagId));
  }

  Future<void> removeTag(int taskId, int tagId) async {
    await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(taskId) & t.tagId.equals(tagId)))
        .go();
  }

  Stream<List<Tag>> watchTags(int taskId) {
    final query = _db.select(_db.tags).join([
      innerJoin(_db.taskTags, _db.taskTags.tagId.equalsExp(_db.tags.id)),
    ])..where(_db.taskTags.taskId.equals(taskId));
    return query.watch().map((rows) => rows.map((r) => r.readTable(_db.tags)).toList());
  }

  /// 硬删除 + 清理绑定。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(id))).go();
      await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
    });
  }

  void _assertWaitingOn(TaskDraft draft) {
    if (draft.status == TaskStatus.waiting &&
        (draft.waitingOn == null || draft.waitingOn!.trim().isEmpty)) {
      throw ArgumentError('waiting_on is required for waiting tasks');
    }
  }

  /// 今日 23:59:59.999 的 ms epoch（以注入时钟 [_now] 取「当前」时刻，
  /// 默认 `DateTime.now`；测试可注入固定时刻消除跨午夜竞态）。
  int _endOfTodayMs() {
    final now = _now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;
  }
}
