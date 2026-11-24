import 'package:drift/drift.dart';
import 'package:gtd_app/data/migrations/migration_steps.dart';

part 'tables.g.dart';

class InboxItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rawText => text()();
  TextColumn get source => text()(); // text / voice / share / image
  TextColumn get aiHint => text().nullable()(); // M2
  TextColumn get promptVersion => text().nullable()(); // M2
  TextColumn get status => text()(); // pending / clarified
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get goal => text().nullable()();
  TextColumn get status => text()(); // active / done / someday
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class Contexts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get color => text()(); // 如 #1A73E8
}

@TableIndex(name: 'idx_tasks_project', columns: {#projectId})
@TableIndex(name: 'idx_tasks_context', columns: {#contextId})
@TableIndex(name: 'idx_tasks_status', columns: {#status})
@TableIndex(name: 'idx_tasks_due_date', columns: {#dueDate})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text()(); // next_action / waiting / someday / done
  IntColumn get dueDate => integer().nullable()();
  IntColumn get scheduled => integer().nullable()();
  TextColumn get energy => text().nullable()(); // low / medium / high
  TextColumn get priority => text().nullable()(); // low / medium / high
  TextColumn get waitingOn => text().nullable()();
  IntColumn get projectId => integer().nullable().references(Projects, #id)();
  IntColumn get contextId => integer().nullable().references(Contexts, #id)();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class TaskTags extends Table {
  IntColumn get taskId => integer().references(Tasks, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();
  @override
  Set<Column> get primaryKey => {taskId, tagId};
}

class Reviews extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get date => integer()(); // 当日起始毫秒
  TextColumn get summary => text().nullable()();
  TextColumn get stats => text().nullable()(); // {"done":n,"new":n,"stalled":n}
  TextColumn get aiReport => text().nullable()(); // M2
  IntColumn get createdAt => integer()();
}

@DriftDatabase(tables: [InboxItems, Tasks, Projects, Contexts, Tags, TaskTags, Reviews])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultContexts();
        },
        onUpgrade: (m, from, to) async {
          await applyMigrations(m, from, to);
        },
      );

  Future<void> _seedDefaultContexts() async {
    final existing = await (select(contexts)..limit(1)).get();
    if (existing.isNotEmpty) return;
    await into(contexts).insert(ContextsCompanion.insert(name: '@电脑', sort: const Value(0)));
    await into(contexts).insert(ContextsCompanion.insert(name: '@外出', sort: const Value(1)));
    await into(contexts).insert(ContextsCompanion.insert(name: '@电话', sort: const Value(2)));
  }
}
