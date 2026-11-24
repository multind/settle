import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/tables.dart';
import '../test_utils.dart';

void main() {
  late AppDatabase db;
  late ReviewRepository repo;
  setUp(() {
    db = createTestDatabase();
    repo = ReviewRepository(db);
  });
  tearDown(() => db.close());

  test('create 保存日期/总结/统计 JSON', () async {
    final dayStart = DateTime(2026, 11, 23).millisecondsSinceEpoch;
    final r = await repo.create(
      date: dayStart,
      summary: '本周专注客户交付',
      stats: '{"done":3,"new":2,"stalled":1}',
    );
    expect(r.date, dayStart);
    expect(r.summary, '本周专注客户交付');
    expect(r.stats, '{"done":3,"new":2,"stalled":1}');
  });

  test('update 修改总结与统计', () async {
    final r = await repo.create(date: 1, summary: 'a', stats: '{"done":1,"new":0,"stalled":0}');
    await repo.update(r.id, summary: 'b', stats: '{"done":4,"new":1,"stalled":0}');
    final after = await repo.byId(r.id);
    expect(after!.summary, 'b');
    expect(after.stats, contains('"done":4'));
  });

  test('watchAll 按日期倒序', () async {
    await repo.create(date: 2, summary: '后');
    await repo.create(date: 1, summary: '先');
    final rows = await repo.watchAll().first;
    expect(rows.map((r) => r.summary).toList(), ['后', '先']);
  });

  test('delete 硬删除', () async {
    final r = await repo.create(date: 1, summary: 'x');
    await repo.delete(r.id);
    expect(await db.select(db.reviews).get(), isEmpty);
  });
}
