import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/tables.dart';

class TaskRepository {
  TaskRepository(this._db);
  final AppDatabase _db;

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
    return (await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingle());
  }

  void _assertWaitingOn(TaskDraft draft) {
    if (draft.status == TaskStatus.waiting &&
        (draft.waitingOn == null || draft.waitingOn!.trim().isEmpty)) {
      throw ArgumentError('waiting_on is required for waiting tasks');
    }
  }
}
