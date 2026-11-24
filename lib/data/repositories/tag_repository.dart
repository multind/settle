import 'package:drift/drift.dart';
import 'package:gtd_app/data/tables.dart';

class TagRepository {
  TagRepository(this._db);
  final AppDatabase _db;

  Stream<List<Tag>> watchAll() =>
      (_db.select(_db.tags)..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<List<Tag>> getAll() async => _db.select(_db.tags).get();

  Future<Tag?> byId(int id) async =>
      (_db.select(_db.tags)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Tag> create({required String name, required String color}) async {
    final id = await _db.into(_db.tags).insert(TagsCompanion.insert(name: name, color: color));
    return (await byId(id))!;
  }

  Future<void> update(int id, {String? name, String? color}) async {
    await (_db.update(_db.tags)..where((t) => t.id.equals(id))).write(TagsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      color: color == null ? const Value.absent() : Value(color),
    ));
  }

  /// 硬删除 + 解绑：先删所有 task_tags 关联，再删标签。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.delete(_db.taskTags)..where((t) => t.tagId.equals(id))).go();
      await (_db.delete(_db.tags)..where((t) => t.id.equals(id))).go();
    });
  }
}
