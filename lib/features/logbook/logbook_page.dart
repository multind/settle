import 'package:flutter/material.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 日志视图（index 8）：`watchDone`（done，completedAt DESC 已由数据层排序）归档。
/// 顶部搜索按标题过滤（大小写不敏感，本地内存过滤）；行 = 标题 + 完成时间
/// （`yyyy-MM-dd HH:mm` 本地时间）+ [恢复]（reopen 清 completedAt）+
/// [删除]（确认对话框 → delete）。已完成任务不再提供 complete（无完成钮）；
/// 行只读不做编辑，保持极简。空态 `logbookEmpty`。
/// 公共组件 `TaskListView`：reverseChronological 排序（completedAt 倒序）、
/// logbook 行变体（无完成钮，保留恢复/删除 Keys）；批量操作 = 恢复/删除子集。
/// 仓库约定：普通 Provider 无 watchByStatus 成员，改文件级 StreamProvider。
final _logbookProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchDone());

class LogbookPage extends ConsumerStatefulWidget {
  const LogbookPage({super.key});

  @override
  ConsumerState<LogbookPage> createState() => _LogbookPageState();
}

class _LogbookPageState extends ConsumerState<LogbookPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasks = ref.watch(_logbookProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLogbook)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: TextField(
            key: const Key('logbook_search'),
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: l10n.logbookSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (rows) {
              final filtered = rows
                  .where((t) => t.title.toLowerCase().contains(_query))
                  .toList();
              if (filtered.isEmpty) {
                // 空串（未搜索）→ 归档空态；搜索无匹配 → 独立「无匹配任务」文案。
                return Center(
                  child: Text(_query.isEmpty
                      ? l10n.logbookEmpty
                      : l10n.logbookSearchEmpty),
                );
              }
              return TaskListView(
                tasks: filtered,
                reorderEnabled: false,
                selectionEnabled: true,
                focusEnabled: true,
                sortMode: TaskSortMode.reverseChronological,
                rowVariant: TaskRowVariant.logbook,
                actions: const [TaskListAction.restore, TaskListAction.delete],
                subtitleBuilder: (context, t) {
                  if (t.completedAt == null) return null;
                  final isLight =
                      Theme.of(context).brightness == Brightness.light;
                  final tokens = isLight ? AppTokens.light : AppTokens.dark;
                  return Text(
                    _formatCompletedAt(t.completedAt!),
                    style: TextStyle(color: tokens.muted, fontSize: 12),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  /// `yyyy-MM-dd HH:mm` 本地时间（不引入 intl，手工补零）。
  static String _formatCompletedAt(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
