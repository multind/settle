import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';

/// 全库 JSON 备份导出/恢复（规格 §9.2）。导出覆盖 6 实体 + task_tags 关联。
class ExportService {
  ExportService(this._db)
      : _inbox = InboxRepository(_db),
        _tasks = TaskRepository(_db),
        _projects = ProjectRepository(_db),
        _contexts = ContextRepository(_db),
        _tags = TagRepository(_db),
        _reviews = ReviewRepository(_db);

  final AppDatabase _db;
  final InboxRepository _inbox;
  final TaskRepository _tasks;
  final ProjectRepository _projects;
  final ContextRepository _contexts;
  final TagRepository _tags;
  final ReviewRepository _reviews;

  Future<String> exportJson() async {
    return jsonEncode({
      'app': 'gtd',
      'version': 1,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'inbox_items': await _inbox.getAll(),
      'projects': await _projects.getAll(),
      'contexts': await _contexts.getAll(),
      'tags': await _tags.getAll(),
      'tasks': await _tasks.getAll(),
      'task_tags': await _db.select(_db.taskTags).get(),
      'reviews': await _reviews.getAll(),
    });
  }

  Future<void> importJson(String raw) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['app'] != 'gtd' || data['version'] != 1) {
      throw const FormatException('Not a valid GTD backup');
    }
    await _db.transaction(() async {
      await _db.delete(_db.reviews).go();
      await _db.delete(_db.taskTags).go();
      await _db.delete(_db.tasks).go();
      await _db.delete(_db.tags).go();
      await _db.delete(_db.contexts).go();
      await _db.delete(_db.projects).go();
      await _db.delete(_db.inboxItems).go();

      for (final raw in data['projects'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.projects).insert(ProjectsCompanion(
          id: Value(m['id'] as int),
          name: Value(m['name'] as String),
          goal: Value(m['goal'] as String?),
          status: Value(m['status'] as String),
          createdAt: Value(m['createdAt'] as int),
          updatedAt: Value(m['updatedAt'] as int),
        ));
      }
      for (final raw in data['contexts'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.contexts).insert(ContextsCompanion(
          id: Value(m['id'] as int),
          name: Value(m['name'] as String),
          icon: Value(m['icon'] as String?),
          sort: Value(m['sort'] as int),
        ));
      }
      for (final raw in data['tags'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.tags).insert(TagsCompanion(
          id: Value(m['id'] as int),
          name: Value(m['name'] as String),
          color: Value(m['color'] as String),
        ));
      }
      for (final raw in data['tasks'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.tasks).insert(TasksCompanion(
          id: Value(m['id'] as int),
          title: Value(m['title'] as String),
          notes: Value(m['notes'] as String?),
          status: Value(m['status'] as String),
          dueDate: Value(m['dueDate'] as int?),
          scheduled: Value(m['scheduled'] as int?),
          energy: Value(m['energy'] as String?),
          priority: Value(m['priority'] as String?),
          waitingOn: Value(m['waitingOn'] as String?),
          projectId: Value(m['projectId'] as int?),
          contextId: Value(m['contextId'] as int?),
          createdAt: Value(m['createdAt'] as int),
          updatedAt: Value(m['updatedAt'] as int),
        ));
      }
      for (final raw in data['task_tags'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.taskTags).insert(TaskTagsCompanion.insert(
          taskId: m['taskId'] as int,
          tagId: m['tagId'] as int,
        ));
      }
      for (final raw in data['inbox_items'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.inboxItems).insert(InboxItemsCompanion(
          id: Value(m['id'] as int),
          rawText: Value(m['rawText'] as String),
          source: Value(m['source'] as String),
          aiHint: Value(m['aiHint'] as String?),
          promptVersion: Value(m['promptVersion'] as String?),
          status: Value(m['status'] as String),
          createdAt: Value(m['createdAt'] as int),
          updatedAt: Value(m['updatedAt'] as int),
        ));
      }
      for (final raw in data['reviews'] as List) {
        final m = raw as Map<String, dynamic>;
        await _db.into(_db.reviews).insert(ReviewsCompanion(
          id: Value(m['id'] as int),
          date: Value(m['date'] as int),
          summary: Value(m['summary'] as String?),
          stats: Value(m['stats'] as String?),
          aiReport: Value(m['aiReport'] as String?),
          createdAt: Value(m['createdAt'] as int),
        ));
      }
    });
  }
}
