import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/core/platform/window_service.dart';
import 'package:settle_app/data/export_service.dart';
import 'package:settle_app/data/repositories/context_repository.dart';
import 'package:settle_app/data/repositories/inbox_repository.dart';
import 'package:settle_app/data/repositories/project_repository.dart';
import 'package:settle_app/data/repositories/review_repository.dart';
import 'package:settle_app/data/repositories/tag_repository.dart';
import 'package:settle_app/data/repositories/task_repository.dart';
import 'package:settle_app/data/tables.dart';
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

/// 平台能力门面（桌面设置 spec）：feature 层唯一平台判定入口。
/// 读 defaultTargetPlatform + kIsWeb（与旧内联判定同一事实源，行为零变化）；
/// Provider 惰性构造一次，全应用共享同一实例（单例语义），测试可 override。
final platformBridgeProvider =
    Provider<PlatformBridge>((ref) => PlatformBridge.detect());

/// 窗口能力服务（桌面设置 spec）：桌面 → DesktopWindowService；移动 →
/// NoopWindowService。feature 层只经此 provider 取服务，永不直接接触平台插件。
final windowServiceProvider = Provider<WindowService>(
  (ref) => createWindowService(
    isDesktop: ref.watch(platformBridgeProvider).isDesktop,
  ),
);
