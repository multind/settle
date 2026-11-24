import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/tables.dart';

class TaskRepository {
  TaskRepository(this._db);
  final AppDatabase _db;

  Stream<List<Task>> watchAll() =>
      (_db.select(_db.tasks)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Stream<List<Task>> watchByStatus(TaskStatus status) =>
      (_db.select(_db.tasks)..where((t) => t.status.equals(status.storage))..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Stream<List<Task>> watchByProject(int projectId) =>
      (_db.select(_db.tasks)..where((t) => t.projectId.equals(projectId))..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Stream<List<Task>> watchByContext(int contextId) =>
      (_db.select(_db.tasks)..where((t) => t.contextId.equals(contextId))..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<Task>> getAll() async => _db.select(_db.tasks).get();

  Future<Task?> byId(int id) async =>
      (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Task> create(TaskDraft draft) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _assertWaitingOn(draft);
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
      createdAt: now,
      updatedAt: now,
    ));
    for (final tagId in draft.tagIds) {
      await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(taskId: id, tagId: tagId));
    }
    return (await byId(id))!;
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
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
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
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      status: Value(status.storage),
      waitingOn: Value(status == TaskStatus.waiting ? waitingOn : null),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> complete(int id) => setStatus(id, TaskStatus.done);

  Future<void> reopen(int id) => setStatus(id, TaskStatus.nextAction);

  Future<void> setProject(int id, int? projectId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      projectId: Value(projectId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
  }

  Future<void> setContext(int id, int? contextId) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(TasksCompanion(
      contextId: Value(contextId),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
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
}
