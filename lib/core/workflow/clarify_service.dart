import 'package:gtd_app/core/models/clarify_decision.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';

/// 手动理清用例（规格 §5.2）：一条 InboxItem 判定为 Task / Project / 删除。
/// Task/Project 落库成功后将条目标为 clarified；删除则硬删条目。
class ClarifyService {
  ClarifyService(this._db, this._inbox, this._tasks, this._projects);

  final AppDatabase _db;
  final InboxRepository _inbox;
  final TaskRepository _tasks;
  final ProjectRepository _projects;

  Future<void> clarify(InboxItem item, ClarifyDecision decision) async {
    await _db.transaction(() async {
      switch (decision) {
        case ClarifyToTask(:final draft):
          await _tasks.create(draft);
        case ClarifyToProject(:final name, :final goal):
          await _projects.create(name: name, goal: goal);
        case ClarifyDelete():
          await _inbox.delete(item.id);
          return;
      }
      await _inbox.markClarified(item.id);
    });
  }
}
