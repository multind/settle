import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 日志视图（index 8）：`watchDone`（done，completedAt DESC 已由数据层排序）归档。
/// 顶部搜索按标题过滤（大小写不敏感，本地内存过滤）；行 = 标题 + 完成时间
/// （`yyyy-MM-dd HH:mm` 本地时间）+ [恢复]（reopen 清 completedAt）+
/// [删除]（确认对话框 → delete）。已完成任务不再提供 complete（无完成钮）；
/// 行只读不做编辑，保持极简。空态 `logbookEmpty`。
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
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: filtered.map((t) => _LogEntryTile(task: t)).toList(),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// 日志行（v0.2 样式，同今日/随时行）：GlassContainer 圆角零阴影；
/// leading 为「已完成」视觉勾选（禁点，不再提供 complete）；
/// subtitle = `yyyy-MM-dd HH:mm` 本地完成时间（muted 小字）；
/// trailing = [恢复]（reopen）与 [删除]（确认对话框）。
class _LogEntryTile extends ConsumerWidget {
  const _LogEntryTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final row = ListTile(
      key: Key('logbook_tile_${task.id}'),
      title: Text(task.title),
      leading: const GlassCheckbox(value: true, onChanged: null),
      subtitle: task.completedAt == null
          ? null
          : Text(
              _formatCompletedAt(task.completedAt!),
              style: TextStyle(color: tokens.muted, fontSize: 12),
            ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        // 图标+tooltip（比文本按钮更稳）：英文 'Restore'/'Delete' 在 280dp
        // 窄屏下文本宽度占满 trailing 槽位，触发 _RenderListTile
        // 「Trailing widget consumes the entire tile width」断言（审查实证）。
        IconButton(
          key: Key('logbook_reopen_${task.id}'),
          tooltip: l10n.logbookRestore,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.replay, size: 20),
          color: tokens.muted,
          onPressed: () => ref.read(taskRepositoryProvider).reopen(task.id),
        ),
        IconButton(
          key: Key('logbook_delete_${task.id}'),
          tooltip: l10n.delete,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.delete_outline, size: 20),
          color: tokens.danger,
          onPressed: () => _confirmDelete(context, ref, l10n),
        ),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        color: tokens.cardSolid,
        blur: 5,
        saturate: 1.0,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        shadow: tokens.shadowSm,
        child: row,
      ),
    );
  }

  /// `yyyy-MM-dd HH:mm` 本地时间（不引入 intl，手工补零）。
  static String _formatCompletedAt(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  /// 删除确认对话框：确认后才调 `delete`（.then 避免跨异步用 context）。
  void _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logbookDeleteConfirm),
        content: Text(l10n.confirmDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('logbook_confirm_delete'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(taskRepositoryProvider).delete(task.id);
      }
    });
  }
}
