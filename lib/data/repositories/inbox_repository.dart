import 'package:drift/drift.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/tables.dart';

class InboxRepository {
  InboxRepository(this._db);
  final AppDatabase _db;

  Stream<List<InboxItem>> watchAll() => (_db.select(_db.inboxItems)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<List<InboxItem>> getAll() async => _db.select(_db.inboxItems).get();

  Future<InboxItem?> byId(int id) async =>
      (_db.select(_db.inboxItems)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<InboxItem> add({required String rawText, required TaskSource source}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: rawText,
      source: source.storage,
      status: InboxStatus.pending.storage,
      createdAt: now,
      updatedAt: now,
    ));
    return (await byId(id))!;
  }

  Future<void> updateRawText(int id, String rawText) async {
    await (_db.update(_db.inboxItems)..where((t) => t.id.equals(id))).write(
      InboxItemsCompanion(
        rawText: Value(rawText),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> markClarified(int id) async {
    await (_db.update(_db.inboxItems)..where((t) => t.id.equals(id))).write(
      InboxItemsCompanion(
        status: Value(InboxStatus.clarified.storage),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.inboxItems)..where((t) => t.id.equals(id))).go();
  }
}
