import 'package:drift/drift.dart';
import 'package:settle_app/data/tables.dart';

class ContextRepository {
  ContextRepository(this._db);
  final AppDatabase _db;

  Stream<List<Context>> watchAll() =>
      (_db.select(_db.contexts)..orderBy([(t) => OrderingTerm.asc(t.sort), (t) => OrderingTerm.asc(t.id)]))
          .watch();

  Future<List<Context>> getAll() async => _db.select(_db.contexts).get();

  Future<Context?> byId(int id) async =>
      (_db.select(_db.contexts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Context> create({required String name, String? icon}) async {
    final id = await _db.into(_db.contexts).insert(ContextsCompanion.insert(
      name: name,
      icon: Value(icon),
      sort: const Value(0),
    ));
    return (await byId(id))!;
  }

  Future<void> update(int id, {String? name, String? icon, int? sort}) async {
    await (_db.update(_db.contexts)..where((t) => t.id.equals(id))).write(ContextsCompanion(
      name: name == null ? const Value.absent() : Value(name),
      icon: icon == null ? const Value.absent() : Value(icon),
      sort: sort == null ? const Value.absent() : Value(sort),
    ));
  }

  /// 硬删除 + 置空：先清空关联 Task 的 context_id，再删情境。
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.contextId.equals(id))).write(
        TasksCompanion(
          contextId: const Value(null),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      await (_db.delete(_db.contexts)..where((t) => t.id.equals(id))).go();
    });
  }
}
