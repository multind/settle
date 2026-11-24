import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/data/export_service.dart';
import 'package:gtd_app/data/repositories/context_repository.dart';
import 'package:gtd_app/data/repositories/inbox_repository.dart';
import 'package:gtd_app/data/repositories/project_repository.dart';
import 'package:gtd_app/data/repositories/review_repository.dart';
import 'package:gtd_app/data/repositories/tag_repository.dart';
import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 数据库实例由 main() 打开后 override 注入（无全局单例，M3 多账户可加作用域）。
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider 必须在 main/测试中 override');
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider 必须在 main/测试中 override');
});

final inboxRepositoryProvider = Provider<InboxRepository>(
    (ref) => InboxRepository(ref.watch(databaseProvider)));
final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => TaskRepository(ref.watch(databaseProvider)));
final projectRepositoryProvider = Provider<ProjectRepository>(
    (ref) => ProjectRepository(ref.watch(databaseProvider)));
final contextRepositoryProvider = Provider<ContextRepository>(
    (ref) => ContextRepository(ref.watch(databaseProvider)));
final tagRepositoryProvider = Provider<TagRepository>(
    (ref) => TagRepository(ref.watch(databaseProvider)));
final reviewRepositoryProvider = Provider<ReviewRepository>(
    (ref) => ReviewRepository(ref.watch(databaseProvider)));
final exportServiceProvider = Provider<ExportService>(
    (ref) => ExportService(ref.watch(databaseProvider)));
