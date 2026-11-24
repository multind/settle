import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late InboxRepository repo;
  setUp(() {
    db = createTestDatabase();
    repo = InboxRepository(db);
  });
  tearDown(() => db.close());

  test('add 创建 pending 条目并带时间戳', () async {
    final item = await repo.add(rawText: '写周报', source: TaskSource.text);
    expect(item.rawText, '写周报');
    expect(item.source, 'text');
    expect(item.status, 'pending');
    expect(item.createdAt, greaterThan(0));
    expect(item.updatedAt, greaterThan(0));
  });

  test('updateRawText 更新原文与 updatedAt', () async {
    final item = await repo.add(rawText: '旧', source: TaskSource.text);
    await repo.updateRawText(item.id, '新');
    final updated = await repo.byId(item.id);
    expect(updated!.rawText, '新');
    expect(updated.updatedAt, greaterThanOrEqualTo(item.updatedAt));
  });

  test('markClarified 置为 clarified', () async {
    final item = await repo.add(rawText: 'x', source: TaskSource.text);
    await repo.markClarified(item.id);
    expect((await repo.byId(item.id))!.status, 'clarified');
  });

  test('delete 硬删除', () async {
    final item = await repo.add(rawText: 'x', source: TaskSource.text);
    await repo.delete(item.id);
    expect(await repo.byId(item.id), isNull);
    expect(await db.select(db.inboxItems).get(), isEmpty);
  });

  test('watchAll 按创建时间倒序推送', () async {
    await repo.add(rawText: '先', source: TaskSource.text);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repo.add(rawText: '后', source: TaskSource.text);
    final rows = await repo.watchAll().first;
    expect(rows.map((e) => e.rawText).toList(), ['后', '先']);
  });
}
