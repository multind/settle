import 'package:drift/drift.dart';
import 'package:settle_app/data/tables.dart';

class ReviewRepository {
  ReviewRepository(this._db);
  final AppDatabase _db;

  Stream<List<Review>> watchAll() =>
      (_db.select(_db.reviews)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<List<Review>> getAll() async => _db.select(_db.reviews).get();

  Future<Review?> byId(int id) async =>
      (_db.select(_db.reviews)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Review> create({
    required int date,
    String? summary,
    String? stats,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _db.into(_db.reviews).insert(ReviewsCompanion.insert(
      date: date,
      summary: Value(summary),
      stats: Value(stats),
      createdAt: now,
    ));
    return (await byId(id))!;
  }

  Future<void> update(int id, {String? summary, String? stats}) async {
    await (_db.update(_db.reviews)..where((t) => t.id.equals(id))).write(ReviewsCompanion(
      summary: summary == null ? const Value.absent() : Value(summary),
      stats: stats == null ? const Value.absent() : Value(stats),
    ));
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.reviews)..where((t) => t.id.equals(id))).go();
  }
}
