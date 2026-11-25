import 'package:drift/drift.dart';

/// 迁移步骤注册表：下标 n 对应 "从版本 n 升级到版本 n+1" 的步骤。
/// 当前已有步骤：下标 0 = v1→v2（Tasks 增 completedAt/sortOrder/repeatRule/reminderAt）。
/// 元素可为 null，表示该版本区间没有迁移步骤。
final List<Future<void> Function(Migrator m)?> migrationSteps = [
  // v1 → v2：Tasks 表补齐时间维度字段。
  (m) async {
    await m.database.customStatement('ALTER TABLE tasks ADD COLUMN completed_at INTEGER;');
    await m.database.customStatement('ALTER TABLE tasks ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;');
    await m.database.customStatement('ALTER TABLE tasks ADD COLUMN repeat_rule TEXT;');
    await m.database.customStatement('ALTER TABLE tasks ADD COLUMN reminder_at INTEGER;');
    // 回填：既有任务按 id 顺序（与旧 order by id 等价）。
    await m.database.customStatement('UPDATE tasks SET sort_order = id;');
  },
];

/// 按版本区间依次执行迁移步骤。
Future<void> applyMigrations(Migrator m, int from, int to) async {
  for (var version = from; version < to; version++) {
    final step = migrationSteps[version - 1];
    if (step != null) {
      await step(m);
    }
  }
}
