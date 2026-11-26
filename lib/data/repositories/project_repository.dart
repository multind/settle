import 'package:drift/drift.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/tables.dart';

class ProjectRepository {
  ProjectRepository(this._db);
  final AppDatabase _db;

  Stream<List<Project>> watchAll() =>
      (_db.select(_db.projects)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();

  Future<List<Project>> getAll() async => _db.select(_db.projects).get();

  Future<Project?> byId(int id) async =>
      (_db.select(_db.projects)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Project> create({
    required String name,
    String? goal,
    ProjectStatus status = ProjectStatus.active,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.projects).insert(ProjectsCompanion.insert(
      name: name,
      goal: Value(goal),
      status: status.storage,
      createdAt: now,
      updatedAt: now,
    ));
    return (await byId(id))!;
  }

  Future<void> updateNameAndGoal(int id, {required String name, String? goal}) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        name: Value(name),
        goal: Value(goal),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setStatus(int id, ProjectStatus status) async {
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(
        status: Value(status.storage),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// 硬删除 + 级联：先删该项目下所有 Task 的 tag 绑定与 Task 本身，再删项目。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final taskIds = (await (_db.select(_db.tasks)..where((t) => t.projectId.equals(id))).get())
          .map((t) => t.id)
          .toList();
      for (final taskId in taskIds) {
        await (_db.delete(_db.taskTags)..where((t) => t.taskId.equals(taskId))).go();
        await (_db.delete(_db.tasks)..where((t) => t.id.equals(taskId))).go();
      }
      await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
    });
  }
}
