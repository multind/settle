import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 多选批量动作类型。真实动作实现由 v0.3 交互计划 Task 2 接线；
/// 本组件仅定义签名与选择栏按钮（[TaskListView.onAction] 可传 null）。
enum TaskListAction { complete, delete, setDate, move, restore }

/// 行变体：standard = 完成钮 + 点击编辑；logbook = 已完成行
/// （无完成钮，保留恢复/删除 icon 按钮）。
enum TaskRowVariant { standard, logbook }

/// 排序模式：standard = 优先级→sortOrder→id 升序（终局 tiebreak）；
/// reverseChronological = completedAt 倒序（null 最后，再 id 倒序，watchDone 口径）。
enum TaskSortMode { standard, reverseChronological }

/// 六视图统一任务列表组件（v0.3 交互层，收敛各页私有 `_TaskTile`）。
///
/// 三态互斥：
/// - **重排**（[reorderEnabled]）：`ReorderableListView` + `onReorderItem`
///   （v3.41 起 `newIndex` 已折算为「移除后」列表插入位，不再手工 -1），
///   落库 `repository.reorder(orderedIds)`；触屏 = 整行长按延迟拖拽，
///   桌面 = 行内拖拽手柄；组头（[buildDateHeader] 渲染）无手柄、不可拖。
///   分组存在（[groupKey]）时只允许组内重排：跨组拖动 no-op 弹回。
///   重排模式不触发长按多选。
/// - **多选**（[selectionEnabled]）：长按行进入；行前 `GlassCheckbox` 勾选
///   （点选切换）；顶栏「已选 N 项」+ 操作按钮 + 退出 X；多选模式禁用拖动。
/// - **焦点**（[focusEnabled]）：行可获焦并高亮（桌面），供快捷键（Task 4）接线。
///
/// 排序在组件内统一完成（[sortMode]），六页既有排序比较器差异在此收敛。
/// 可选分组：给 [groupKey] 时按组键升序分组渲染，组首插入 [buildDateHeader]
/// 组头（即将页日期头 / 今日逾期区标题；拖到日期的 DragTarget 由 Task 3 加在头上）。
class TaskListView extends ConsumerStatefulWidget {
  const TaskListView({
    super.key,
    required this.tasks,
    this.reorderEnabled = false,
    this.selectionEnabled = false,
    this.focusEnabled = false,
    this.sortMode = TaskSortMode.standard,
    this.rowVariant = TaskRowVariant.standard,
    this.actions = const [],
    this.onAction,
    this.groupKey,
    this.buildDateHeader,
    this.subtitleBuilder,
    this.isOverdue,
  });

  /// 任务列表（组件内按 [sortMode] 排序；以组件内排序为准，收敛各页差异）。
  final List<Task> tasks;

  /// 重排开（今日/随时/即将）。
  final bool reorderEnabled;

  /// 多选开（六页全开）。
  final bool selectionEnabled;

  /// 焦点开（桌面；Task 4 快捷键接线）。
  final bool focusEnabled;

  /// 排序模式（日志 = [TaskSortMode.reverseChronological]）。
  final TaskSortMode sortMode;

  /// 行变体（日志 = [TaskRowVariant.logbook]）。
  final TaskRowVariant rowVariant;

  /// 选择模式顶栏展示的操作按钮集合（按视图裁剪；日志 = 恢复/删除子集）。
  final List<TaskListAction> actions;

  /// 批量操作回调（Task 2 接线实现；本 Task 仅定义签名，可传 null）。
  final void Function(TaskListAction action, Set<int> taskIds)? onAction;

  /// 组键（Comparable）：非空时任务分组渲染（组按键升序，组内按比较器序），
  /// 组首插入 [buildDateHeader] 组头。即将页 = 生效日 DateTime，今日 = 逾期 0/今日 1。
  final Comparable Function(Task task)? groupKey;

  /// 组头构建器（即将页日期头 / 今日逾期区标题；Task 3 在即将页头上挂 DragTarget）。
  final Widget Function(BuildContext context, Comparable key)? buildDateHeader;

  /// 行字幕覆盖（today=日期+逾期色，waiting=waitingOn，logbook=完成时间）；
  /// 返回 null 表示该行无字幕。
  final Widget? Function(BuildContext context, Task task)? subtitleBuilder;

  /// 逾期行判定（今日页）：true 时行左侧加 danger 色条。
  final bool Function(Task task)? isOverdue;

  @override
  TaskListViewState createState() => TaskListViewState();
}

class TaskListViewState extends ConsumerState<TaskListView> {
  /// 渲染顺序的任务列表（排序 + 分组展平）；重排模式由 [ReorderableListView.onReorder]
  /// 就地变更，数据层落库后随 stream 回填（didUpdateWidget 重算）。
  late List<Task> _items;

  bool _selectionMode = false;
  final Set<int> _selected = {};
  int _focusIndex = 0;

  /// 行 id → 焦点节点（Task 4 用 [moveFocus]/[focusRow] 请求键盘焦点）。
  final Map<int, FocusNode> _focusNodes = {};

  /// 当前 build 的 child → `_items` 索引映射（-1 = 组头），供 onReorder 换算。
  List<int> _childPositions = const [];

  @override
  void initState() {
    super.initState();
    _items = _buildOrdered(widget.tasks);
  }

  @override
  void didUpdateWidget(covariant TaskListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.tasks, widget.tasks)) {
      final next = _buildOrdered(widget.tasks);
      _items = next;
      final ids = {for (final t in next) t.id};
      // 清理离场行焦点节点（帧末销毁，避免销毁树中仍在引用的节点）。
      final stale = <FocusNode>[];
      _focusNodes.removeWhere((id, node) {
        if (ids.contains(id)) return false;
        stale.add(node);
        return true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in stale) {
          node.dispose();
        }
      });
      _focusIndex = _items.isEmpty ? 0 : _focusIndex.clamp(0, _items.length - 1);
      _selected.removeWhere((id) => !ids.contains(id));
      if (_selected.isEmpty) _selectionMode = false;
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // —— 排序比较器（公共统一，六页差异收敛点）——

  static int _priorityIndex(String? p) => switch (p) {
        'high' => 0,
        'medium' => 1,
        'low' => 2,
        _ => 3,
      };

  /// 标准：优先级 → sortOrder → id 升序终局 tiebreak
  /// （today/anytime 收尾清单：tiebreak 统一为 sortOrder → id）。
  static int _standardCompare(Task a, Task b) {
    final pa = _priorityIndex(a.priority);
    final pb = _priorityIndex(b.priority);
    if (pa != pb) return pa.compareTo(pb);
    final so = a.sortOrder.compareTo(b.sortOrder);
    if (so != 0) return so;
    return a.id.compareTo(b.id);
  }

  /// 日志：completedAt 倒序（null 最后），再 id 倒序（与 watchDone 口径一致）。
  static int _reverseChronologicalCompare(Task a, Task b) {
    final ca = a.completedAt;
    final cb = b.completedAt;
    if (ca == null && cb == null) return b.id.compareTo(a.id);
    if (ca == null) return 1;
    if (cb == null) return -1;
    final c = cb.compareTo(ca);
    return c != 0 ? c : b.id.compareTo(a.id);
  }

  /// 排序后展平：可选分组（组按键升序，组内保持比较器序）。
  List<Task> _buildOrdered(List<Task> tasks) {
    final sorted = tasks.toList()
      ..sort(widget.sortMode == TaskSortMode.reverseChronological
          ? _reverseChronologicalCompare
          : _standardCompare);
    if (widget.groupKey == null) return sorted;
    final groups = <Comparable, List<Task>>{};
    for (final t in sorted) {
      groups.putIfAbsent(widget.groupKey!(t), () => []).add(t);
    }
    final keys = groups.keys.toList()..sort((a, b) => a.compareTo(b));
    return [for (final key in keys) ...groups[key]!];
  }

  // —— 对外 API（Task 4 快捷键接线用）——

  int get focusIndex => _focusIndex;

  Task? get focusedTask =>
      _items.isEmpty || _focusIndex >= _items.length ? null : _items[_focusIndex];

  bool get selectionMode => _selectionMode;

  Set<int> get selectedIds => Set.unmodifiable(_selected);

  /// 焦点移动（列表内循环）；请求新焦点行的键盘焦点。
  void moveFocus(int delta) {
    if (!widget.focusEnabled || _items.isEmpty) return;
    setState(() {
      _focusIndex = (_focusIndex + delta) % _items.length;
      if (_focusIndex < 0) _focusIndex = _items.length - 1;
    });
    _focusNodes[_items[_focusIndex].id]?.requestFocus();
  }

  void focusRow(int index) {
    if (!widget.focusEnabled || _items.isEmpty) return;
    setState(() => _focusIndex = index.clamp(0, _items.length - 1));
    _focusNodes[_items[_focusIndex].id]?.requestFocus();
  }

  void exitSelection() {
    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  // —— 构建 ——

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final positions = <int>[];
    Comparable? lastGroup;
    var childIndex = 0;
    // 桌面平台（Windows/macOS/Linux）：行内拖拽手柄（ReorderableDragStartListener
    // 按下即拖，仅包手柄图标，不劫持整行点击/完成钮）；触屏：整行长按延迟拖拽。
    final isDesktop = switch (Theme.of(context).platform) {
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux => true,
      _ => false,
    };
    for (var i = 0; i < _items.length; i++) {
      final t = _items[i];
      final group = widget.groupKey?.call(t);
      if (group != null && (lastGroup == null || group.compareTo(lastGroup) != 0)) {
        // 组头：KeyedSubtree 占位，绝不挂拖拽监听（Task 3 会在上面放 DragTarget）。
        children.add(KeyedSubtree(
          key: ValueKey('task_header_$group'),
          child: widget.buildDateHeader?.call(context, group) ??
              const SizedBox.shrink(),
        ));
        positions.add(-1);
        lastGroup = group;
        childIndex++;
      }
      final draggable = widget.reorderEnabled && !_selectionMode;
      if (draggable && isDesktop) {
        children.add(_buildRow(i, dragIndex: childIndex));
      } else if (draggable) {
        children.add(ReorderableDelayedDragStartListener(
          key: Key('task_drag_${t.id}'),
          index: childIndex,
          child: _buildRow(i),
        ));
      } else {
        children.add(_buildRow(i));
      }
      positions.add(i);
      childIndex++;
    }
    _childPositions = positions;

    final list = _selectionMode || !widget.reorderEnabled
        ? ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: children,
          )
        : ReorderableListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // 关闭默认手柄：组头不能被包上手柄图标（桌面默认会给每个 child 加）。
            buildDefaultDragHandles: false,
            onReorderItem: _onReorder,
            children: children,
          );
    return Column(
      children: [
        if (_selectionMode) _buildSelectionBar(context),
        Expanded(child: list),
      ],
    );
  }

  /// 重排落点：`onReorderItem` 已把 `newIndex` 折算为「移除后」列表插入位
  /// （reduced child-space；旧 `onReorder` 需手动 -1，v3.41 起弃用）。
  /// 组头是 child 空间占位（`_childPositions` 记 -1），换算回 `_items` 索引。
  /// 分组存在时只允许组内重排：目标插入位的归属按 **child 空间左侧相邻 child**
  /// 判定（任务行 → 该行组；组头 → 该组头引入的组，即「该组顶部槽位」属组内）。
  /// 跨组拖动 no-op 弹回，不写库（避免 sortOrder 跨组污染与 stream 回填闪烁回跳）。
  void _onReorder(int oldIndex, int newIndex) {
    if (_items.isEmpty) return;
    final positions = _childPositions;
    if (oldIndex < 0 || oldIndex >= positions.length) return;
    final srcItem = positions[oldIndex];
    if (srcItem < 0) return; // 组头不可拖。
    // reduced child 空间 = 去掉被拖行后的顺序。拖拽动画期间 _items 未变、
    // _childPositions 仍是构建时的原始映射，这里仅做空间换算，不修改 _items。
    final reduced = <int>[];
    for (var j = 0; j < positions.length; j++) {
      if (j != oldIndex) reduced.add(positions[j]);
    }
    // 目标槽位在 _items 中的插入位 = reduced 空间 newIndex 之前的非组头数量。
    var destItem = 0;
    for (var j = 0; j < newIndex && j < reduced.length; j++) {
      if (reduced[j] != -1) destItem++;
    }
    if (widget.groupKey != null) {
      final srcGroup = widget.groupKey!(_items[srcItem]);
      final destGroup = _slotGroup(newIndex, positions, oldIndex);
      if (destGroup != null && srcGroup.compareTo(destGroup) != 0) {
        return; // 跨组 → no-op。
      }
    }
    setState(() {
      final moved = _items.removeAt(srcItem);
      _items.insert(destItem.clamp(0, _items.length), moved);
    });
    ref.read(taskRepositoryProvider).reorder(_items.map((t) => t.id).toList());
  }

  /// 目标插入位归属组：reduced 空间插入位 `newIndex` 的左侧相邻 child 决定。
  /// - 任务行 → 该行组；
  /// - 组头 → 该组头引入的组（目标槽位即「该组顶部槽位」，属组内重排，应允许）。
  /// 组头组归属查 **原始（pre-removal）child 空间**：组头之后第一个任务行即该组
  /// （被拖行是该组唯一一行时，其组头后面仍能找到该行，避免误判跨组）。
  /// `leftReduced < oldIndex ? leftReduced : leftReduced + 1` 为 reduced → 原始索引映射。
  Comparable? _slotGroup(int newIndex, List<int> positions, int oldIndex) {
    if (newIndex == 0) {
      // 最顶部槽位（首个组头之上）→ 首组。
      for (var j = 0; j < positions.length; j++) {
        if (positions[j] != -1) return widget.groupKey!(_items[positions[j]]);
      }
      return null;
    }
    final leftReduced = newIndex - 1;
    final origLeft = leftReduced < oldIndex ? leftReduced : leftReduced + 1;
    final leftPos = positions[origLeft];
    if (leftPos != -1) return widget.groupKey!(_items[leftPos]);
    // 左邻是组头 → 该组头引入的组 = 原始空间里它后面第一个任务行的组。
    for (var j = origLeft + 1; j < positions.length; j++) {
      if (positions[j] != -1) return widget.groupKey!(_items[positions[j]]);
    }
    return null;
  }

  Widget _buildRow(int index, {int? dragIndex}) {
    final t = _items[index];
    final focused = widget.focusEnabled && !_selectionMode && index == _focusIndex;
    final selected = _selected.contains(t.id);
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;

    final ListTile tile = widget.rowVariant == TaskRowVariant.logbook
        ? _buildLogbookTile(t, l10n, tokens, selected)
        : _buildStandardTile(t, l10n, tokens, selected, dragIndex);

    Widget row = GlassContainer(
      color: focused ? tokens.selectedBg : tokens.cardSolid,
      blur: 5,
      saturate: 1.0,
      borderColor: tokens.stroke,
      borderRadius: BorderRadius.circular(AppTokens.radiusRow),
      shadow: tokens.shadowSm,
      child: tile,
    );
    // 逾期行：左侧 1px danger 色条（描边在圆角容器外，视觉独立于 hairline）。
    if (widget.isOverdue?.call(t) ?? false) {
      row = Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: tokens.danger, width: 1)),
          borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        ),
        child: row,
      );
    }
    final rowWidget = Padding(
      key: Key('task_row_${t.id}'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: row,
    );
    if (!widget.focusEnabled) return rowWidget;
    return Focus(
      key: Key('task_focus_${t.id}'),
      focusNode:
          _focusNodes.putIfAbsent(t.id, () => FocusNode(debugLabel: 'task_focus_${t.id}')),
      onFocusChange: (hasFocus) {
        if (hasFocus && !_selectionMode) setState(() => _focusIndex = index);
      },
      child: rowWidget,
    );
  }

  ListTile _buildStandardTile(
      Task t, AppLocalizations l10n, AppTokenSet tokens, bool selected,
      int? dragIndex) {
    if (_selectionMode) {
      return ListTile(
        key: Key('task_tile_${t.id}'),
        title: Text(t.title),
        subtitle: widget.subtitleBuilder?.call(context, t),
        leading: GlassCheckbox(
          value: selected,
          onChanged: (_) => _toggleSelect(t.id),
          size: 20,
        ),
        onTap: () => _toggleSelect(t.id),
      );
    }
    return ListTile(
      key: Key('task_tile_${t.id}'),
      title: Text(t.title),
      subtitle: widget.subtitleBuilder?.call(context, t),
      leading: IconButton(
        key: Key('task_done_${t.id}'),
        tooltip: l10n.markDone,
        onPressed: () => ref.read(taskRepositoryProvider).complete(t.id),
        icon: const GlassCheckbox(value: false, onChanged: null),
      ),
      // 桌面重排行：行内拖拽手柄（仅任务行；组头无手柄）。
      trailing: dragIndex == null
          ? null
          : ReorderableDragStartListener(
              key: Key('task_handle_${t.id}'),
              index: dragIndex,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.drag_handle, size: 20, color: tokens.muted),
              ),
            ),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => TaskEditDialog(task: t),
      ),
      // 互斥：重排模式长按为拖拽手柄，不触发多选。
      onLongPress: widget.selectionEnabled && !widget.reorderEnabled
          ? () => _enterSelection(t.id)
          : null,
    );
  }

  ListTile _buildLogbookTile(
      Task t, AppLocalizations l10n, AppTokenSet tokens, bool selected) {
    if (_selectionMode) {
      return ListTile(
        key: Key('logbook_tile_${t.id}'),
        title: Text(t.title),
        subtitle: widget.subtitleBuilder?.call(context, t),
        leading: GlassCheckbox(
          value: selected,
          onChanged: (_) => _toggleSelect(t.id),
          size: 20,
        ),
        onTap: () => _toggleSelect(t.id),
      );
    }
    return ListTile(
      key: Key('logbook_tile_${t.id}'),
      title: Text(t.title),
      subtitle: widget.subtitleBuilder?.call(context, t),
      leading: const GlassCheckbox(value: true, onChanged: null),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        // 图标+tooltip（比文本按钮更稳）：英文 'Restore'/'Delete' 在 280dp
        // 窄屏下文本宽度占满 trailing 槽位，触发 _RenderListTile
        // 「Trailing widget consumes the entire tile width」断言。
        IconButton(
          key: Key('logbook_reopen_${t.id}'),
          tooltip: l10n.logbookRestore,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.replay, size: 20),
          color: tokens.muted,
          onPressed: () => ref.read(taskRepositoryProvider).reopen(t.id),
        ),
        IconButton(
          key: Key('logbook_delete_${t.id}'),
          tooltip: l10n.delete,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.delete_outline, size: 20),
          color: tokens.danger,
          onPressed: () => _confirmDelete(context, t),
        ),
      ]),
      // 互斥：重排模式长按为拖拽手柄，不触发多选。
      onLongPress: widget.selectionEnabled && !widget.reorderEnabled
          ? () => _enterSelection(t.id)
          : null,
    );
  }

  // —— 多选 ——

  void _enterSelection(int id) {
    setState(() {
      _selectionMode = true;
      _selected.add(id);
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Widget _buildSelectionBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Container(
      key: const Key('task_selection_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.stroke)),
      ),
      child: Row(children: [
        IconButton(
          key: const Key('task_selection_exit'),
          tooltip: l10n.exitSelection,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.close),
          onPressed: exitSelection,
        ),
        Expanded(
          child: Text(
            l10n.taskListSelectedCount(_selected.length),
            style: TextStyle(fontWeight: FontWeight.w600, color: tokens.text),
          ),
        ),
        for (final action in widget.actions)
          IconButton(
            key: Key('task_selection_action_${action.name}'),
            tooltip: _actionTooltip(l10n, action),
            visualDensity: VisualDensity.compact,
            // onAction 未接线（Task 1）时禁点；未选中任何行也禁点。
            onPressed: widget.onAction == null || _selected.isEmpty
                ? null
                : () => widget.onAction!(action, _selected.toSet()),
            icon: Icon(_actionIcon(action)),
          ),
      ]),
    );
  }

  IconData _actionIcon(TaskListAction action) => switch (action) {
        TaskListAction.complete => Icons.check,
        TaskListAction.delete => Icons.delete_outline,
        TaskListAction.setDate => Icons.event,
        TaskListAction.move => Icons.drive_file_move_outline,
        TaskListAction.restore => Icons.replay,
      };

  String _actionTooltip(AppLocalizations l10n, TaskListAction action) =>
      switch (action) {
        TaskListAction.complete => l10n.actionComplete,
        TaskListAction.delete => l10n.delete,
        TaskListAction.setDate => l10n.actionSetDate,
        TaskListAction.move => l10n.actionMove,
        TaskListAction.restore => l10n.logbookRestore,
      };

  /// 日志删除确认对话框（保留既有 logbook_confirm_delete Key）。
  Future<void> _confirmDelete(BuildContext context, Task t) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
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
    );
    if (confirmed == true) {
      await ref.read(taskRepositoryProvider).delete(t.id);
    }
  }
}
