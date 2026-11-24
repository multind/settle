import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/export_service.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ExportService service;
  setUp(() {
    db = createTestDatabase();
    service = ExportService(db);
  });
  tearDown(() => db.close());

  Future<void> seedAll() async {
    final inbox = InboxRepository(db);
    final projects = ProjectRepository(db);
    final contexts = ContextRepository(db);
    final tags = TagRepository(db);
    final tasks = TaskRepository(db);
    final reviews = ReviewRepository(db);
    await inbox.add(rawText: '写周报', source: TaskSource.text);
    final p = await projects.create(name: '客户交付', goal: 'g');
    final c = await contexts.create(name: '@电脑');
    final tag = await tags.create(name: '客户', color: '#1A73E8');
    await tasks.create(TaskDraft(
      title: '写初稿', status: TaskStatus.nextAction,
      projectId: p.id, contextId: c.id, tagIds: {tag.id},
    ));
    await reviews.create(date: 1, summary: 's', stats: '{"done":1,"new":0,"stalled":0}');
  }

  test('export 覆盖全部 6+1 实体', () async {
    await seedAll();
    final json = await service.exportJson();
    final map = jsonDecode(json) as Map<String, dynamic>;
    expect(map['app'], 'gtd');
    expect(map['version'], 1);
    expect(map['inbox_items'], hasLength(1));
    expect(map['projects'], hasLength(1));
    expect(map['contexts'], hasLength(4)); // 3 种子 + 1 新建
    expect(map['tags'], hasLength(1));
    expect(map['tasks'], hasLength(1));
    expect(map['task_tags'], hasLength(1));
    expect(map['reviews'], hasLength(1));
    final task0 = (map['tasks'] as List).first as Map<String, dynamic>;
    expect(task0['status'], 'next_action');
    expect(task0['projectId'], pIdFrom(map));
  });

  test('import 恢复全部数据（含 task_tags 关联）', () async {
    await seedAll();
    final json = await service.exportJson();
    // 清空所有表
    await db.delete(db.reviews).go();
    await db.delete(db.taskTags).go();
    await db.delete(db.tasks).go();
    await db.delete(db.tags).go();
    await db.delete(db.contexts).go();
    await db.delete(db.projects).go();
    await db.delete(db.inboxItems).go();
    await service.importJson(json);
    expect(await db.select(db.projects).get(), hasLength(1));
    expect(await db.select(db.tasks).get(), hasLength(1));
    expect(await db.select(db.taskTags).get(), hasLength(1));
    expect(await db.select(db.inboxItems).get(), hasLength(1));
    expect(await db.select(db.reviews).get(), hasLength(1));
    expect(await db.select(db.contexts).get(), hasLength(4));
  });

  test('import 拒绝非法备份', () async {
    expect(() => service.importJson('{"app":"x","version":1}'), throwsFormatException);
    expect(() => service.importJson('{"app":"gtd","version":99}'), throwsFormatException);
  });
}

int pIdFrom(Map<String, dynamic> map) {
  final projects = map['projects'] as List;
  return (projects.first as Map<String, dynamic>)['id'] as int;
}
