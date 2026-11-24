import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import '../test_utils.dart';

void main() {
  test('数据库与仓库 Provider 注入解析（override 内存库）', () {
    final db = createTestDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    expect(container.read(databaseProvider), same(db));
    expect(container.read(inboxRepositoryProvider), isA<InboxRepository>());
    expect(container.read(taskRepositoryProvider), isA<TaskRepository>());
    expect(container.read(projectRepositoryProvider), isA<ProjectRepository>());
  });
}
