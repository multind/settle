import 'package:drift/drift.dart';

/// 迁移步骤注册表：下标 n 对应 "从版本 n 升级到版本 n+1" 的步骤。
/// M1 schemaVersion = 1，无升级步骤；M2 起在此追加（如 references 表）。
/// 元素可为 null，表示该版本区间没有迁移步骤。
final List<Future<void> Function(Migrator m)?> migrationSteps = [];

/// 按版本区间依次执行迁移步骤。
Future<void> applyMigrations(Migrator m, int from, int to) async {
  for (var version = from; version < to; version++) {
    final step = migrationSteps[version - 1];
    if (step != null) {
      await step(m);
    }
  }
}
