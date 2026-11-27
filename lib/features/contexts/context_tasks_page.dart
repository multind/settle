import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';

/// 情境任务流：文件级 StreamProvider.family（contextId 动态，与各页
/// watchByStatus 同款「仓库只暴露方法、页面转 StreamProvider」约定；
/// family 因 id 而异，`ref.watch(_contextTasksProvider(context.id))` 消费）。
/// 情境视图为可行动场景视图：页面层过滤 done（TaskStatus.done.storage），
/// 数据层 watchByContext 零改动（Task 7 裁决：方案 A，主代理 2026-11-27）。
final _contextTasksProvider = StreamProvider.family<List<Task>, int>(
  (ref, contextId) => ref
      .watch(taskRepositoryProvider)
      .watchByContext(contextId)
      .map((rows) =>
          rows.where((t) => t.status != TaskStatus.done.storage).toList()),
);

/// 情境任务页（桌面设置 spec 增补：情境视图，用户确认 2026-11-27 并入本轮）。
/// 情境页 `_ContextTile` 点击 push 进入；AppBar 标题 = 情境名（@ 前缀随用户输入
/// 原样展示，无需额外 title key）；body 复用 TaskListView：
/// - selectionEnabled: true（多选批量）
/// - focusEnabled: 桌面（PlatformBridge.isDesktop → 列表层 J/K/Enter/Delete 复用）
/// - sortMode: standard（统一比较器：优先级 → sortOrder → id）
/// - actions: 仅「完成/删除」子集（跨视图动作如设日期/移动在过滤视角语义弱，裁剪）
/// - reorderEnabled: false（过滤视角，重排与主视图排序冲突）
/// 删除情境仅情境页保留（本页无删除入口，防打开页指向已删情境）；
/// 移动端同样可用（非桌面专属，仅 focusEnabled 随平台自适应）。
class ContextTasksPage extends ConsumerWidget {
  const ContextTasksPage({super.key, required this.context});

  final Context context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ref.watch(platformBridgeProvider).isDesktop;
    final tasks = ref.watch(_contextTasksProvider(this.context.id));
    return Scaffold(
      appBar: AppBar(title: Text(this.context.name)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(
                child: PageRuleHint(
                  icon: Icons.place_outlined,
                  title: l10n.contextTasksEmpty,
                  message: l10n.ruleContextsMessage,
                ),
              )
            : TaskListView(
                tasks: rows,
                selectionEnabled: true,
                focusEnabled: isDesktop,
                sortMode: TaskSortMode.standard,
                actions: const [TaskListAction.complete, TaskListAction.delete],
                reorderEnabled: false,
              ),
      ),
    );
  }
}
