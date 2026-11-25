import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart' show kLongPressTimeout, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
import 'package:gtd_app/features/task/task_list_view.dart';
import 'widget_utils.dart';

/// 文件级私有 StreamProvider（仓库测试惯例）：实时喂 TaskListView 的任务。
final _anytimeProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchAnytime());

final _doneProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchDone());

/// 全部 next_action（含带日期的行，供「重复任务生成副本」用例渲染）。
final _nextActionProvider = StreamProvider<List<Task>>(
    (ref) =>
        ref.watch(taskRepositoryProvider).watchByStatus(TaskStatus.nextAction));

/// 测试宿主：watch 指定 provider 并把数据喂给 TaskListView（默认英文 locale）。
/// 多选/焦点恒为 true（所有用例都依赖选择可用）；重排按用例开关；
/// 动作集默认全集（批量用例可按需裁剪，如日志恢复子集）。
class _Host extends ConsumerWidget {
  const _Host(
    this.provider, {
    this.reorderEnabled = false,
    this.sortMode = TaskSortMode.standard,
    this.rowVariant = TaskRowVariant.standard,
    this.groupKey,
    this.buildDateHeader,
    this.actions = _defaultActions,
    this.dragToDateEnabled = false,
  });

  final StreamProvider<List<Task>> provider;
  final bool reorderEnabled;
  final TaskSortMode sortMode;
  final TaskRowVariant rowVariant;
  final Comparable Function(Task task)? groupKey;
  final Widget Function(BuildContext context, Comparable key)? buildDateHeader;
  final List<TaskListAction> actions;
  final bool dragToDateEnabled;

  static const List<TaskListAction> _defaultActions = [
    TaskListAction.complete,
    TaskListAction.delete,
    TaskListAction.setDate,
    TaskListAction.move,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(provider).value ?? const <Task>[];
    return Scaffold(
      body: TaskListView(
        tasks: tasks,
        reorderEnabled: reorderEnabled,
        selectionEnabled: true,
        focusEnabled: true,
        sortMode: sortMode,
        rowVariant: rowVariant,
        groupKey: groupKey,
        buildDateHeader: buildDateHeader,
        actions: actions,
        dragToDateEnabled: dragToDateEnabled,
      ),
    );
  }
}

/// 分组测试用宿主参数：按标题首字母分两组（'A*' → 0，其余 → 1）。
Comparable _groupOf(Task t) => t.title.startsWith('A') ? 0 : 1;

Widget _groupHeader(BuildContext context, Comparable key) => Text('Group $key');

void main() {
  Future<int> insertTask(TestEnv env, String title, String status,
      {String? priority,
      int? sortOrder,
      DateTime? scheduled,
      String? repeatRule}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      priority: Value(priority),
      scheduled: scheduled == null
          ? const Value.absent()
          : Value(scheduled.millisecondsSinceEpoch),
      repeatRule: repeatRule == null ? const Value.absent() : Value(repeatRule),
      sortOrder: sortOrder == null ? const Value.absent() : Value(sortOrder),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  Future<int> insertDone(TestEnv env, String title, int completedAt) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: 'done',
      completedAt: Value(completedAt),
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  /// 当前 ListTile 的标题顺序（渲染顺序断言用）。
  List<String> tileTitles(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((t) => (t.title as Text).data ?? '')
      .toList();

  testWidgets('普通渲染：完成钮 + 点击行打开编辑对话框', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    expect(find.text('Task A'), findsOneWidget);
    expect(find.text('Task B'), findsOneWidget);
    expect(find.byKey(Key('task_done_$a')), findsOneWidget);
    expect(find.byKey(Key('task_done_$b')), findsOneWidget);
    // 点击行 → TaskEditDialog。
    await tester.tap(find.text('Task A'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskEditDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // 点击完成钮 → done、行消失。
    await tester.tap(find.byKey(Key('task_done_$a')));
    await tester.pumpAndSettle();
    final row =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(a))).getSingle();
    expect(row.status, 'done');
    expect(find.text('Task A'), findsNothing);
    await env.db.close();
  });

  testWidgets('长按进入多选，点选切换，退出 X 关闭', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await insertTask(env, 'Task C', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    // 长按 A → 进入选择模式，A 预选。
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    expect(find.byKey(const Key('task_selection_bar')), findsOneWidget);
    expect(find.text('1 selected'), findsOneWidget);
    // 点选 B → 2 项。
    await tester.tap(find.text('Task B'));
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);
    // 再点 A → 取消选中，回 1 项。
    await tester.tap(find.text('Task A'));
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);
    // 退出 X → 选择栏消失。
    await tester.tap(find.byKey(const Key('task_selection_exit')));
    await tester.pump();
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('重排 onReorder 触发 reorder() 落库（sortOrder 持久化）', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(
        env.wrap(_Host(_anytimeProvider, reorderEnabled: true)));
    await tester.pump();
    // 测试平台 = 移动端分支：整行长按延迟拖拽（无桌面拖拽手柄图标）。
    final gesture = await tester.startGesture(tester.getCenter(find.text('Task A')));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(const Offset(0, 250));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // 落库断言：sortOrder 0 = B，1 = A（A 被拖到 B 之下）。
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b]))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    expect(rows.map((r) => r.id).toList(), [b, a]);
    // 视图即时反映新顺序。
    expect(tileTitles(tester), ['Task B', 'Task A']);
    await env.db.close();
  });

  testWidgets('重排模式不触发长按多选', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await tester.pumpWidget(
        env.wrap(_Host(_anytimeProvider, reorderEnabled: true)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('多选模式禁用拖动（非重排渲染）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    expect(find.byKey(const Key('task_selection_bar')), findsOneWidget);
    expect(find.byType(ReorderableListView), findsNothing);
    await env.db.close();
  });

  testWidgets('选择模式禁用拖到日期 Draggable：长按进选择后无 Draggable', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await tester
        .pumpWidget(env.wrap(_Host(_anytimeProvider, dragToDateEnabled: true)));
    await tester.pump();
    // 普通态：每行包 Draggable<int>（拖到日期源）。
    expect(find.byType(Draggable<int>), findsNWidgets(2));
    // 长按进选择（reorderEnabled 默认关 → 长按 = 多选）；选择模式优先：Draggable 禁用。
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    expect(find.byKey(const Key('task_selection_bar')), findsOneWidget);
    expect(find.byType(Draggable<int>), findsNothing);
    await env.db.close();
  });

  testWidgets('标准排序比较器：优先级 → sortOrder → id 终局', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, '同排同级前', 'next_action', priority: 'low', sortOrder: 10);
    await insertTask(env, '高优先级后', 'next_action', priority: 'high', sortOrder: 5);
    await insertTask(env, '中优先级中', 'next_action', priority: 'medium', sortOrder: 2);
    await insertTask(env, '同排同级后', 'next_action', priority: 'low', sortOrder: 10);
    await insertTask(env, '低优先级前', 'next_action', priority: 'low', sortOrder: 1);
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    expect(tileTitles(tester),
        ['高优先级后', '中优先级中', '低优先级前', '同排同级前', '同排同级后']);
    await env.db.close();
  });

  testWidgets('日志 reverseChronological：completedAt 倒序', (tester) async {
    final env = await TestEnv.create();
    final older = DateTime(2026, 11, 24, 9).millisecondsSinceEpoch;
    final newer = DateTime(2026, 11, 25, 14).millisecondsSinceEpoch;
    await insertDone(env, '旧任务', older);
    await insertDone(env, '新任务', newer);
    await tester.pumpWidget(env.wrap(_Host(
      _doneProvider,
      sortMode: TaskSortMode.reverseChronological,
      rowVariant: TaskRowVariant.logbook,
    )));
    await tester.pump();
    expect(tileTitles(tester), ['新任务', '旧任务']);
    await env.db.close();
  });

  testWidgets('带组头同组重排：组内拖动落库正确（sortOrder 持久化）', (tester) async {
    final env = await TestEnv.create();
    final a1 = await insertTask(env, 'A1', 'next_action');
    final a2 = await insertTask(env, 'A2', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(
      _anytimeProvider,
      reorderEnabled: true,
      groupKey: _groupOf,
      buildDateHeader: _groupHeader,
    )));
    await tester.pump();
    expect(find.text('Group 0'), findsOneWidget);
    // 拖 A1 到 A2 之下（同组，跨组头不存在，组内滑动）。
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('A1')));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // 落库断言：sortOrder 0 = A2，1 = A1。
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a1, a2]))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    expect(rows.map((r) => r.id).toList(), [a2, a1]);
    expect(tileTitles(tester), ['A2', 'A1']);
    await env.db.close();
  });

  testWidgets('跨组拖动被拒绝：no-op 弹回，reorder() 不落库', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'A1', 'next_action', sortOrder: 5);
    final b = await insertTask(env, 'B1', 'next_action', sortOrder: 9);
    await tester.pumpWidget(env.wrap(_Host(
      _anytimeProvider,
      reorderEnabled: true,
      groupKey: _groupOf,
      buildDateHeader: _groupHeader,
    )));
    await tester.pump();
    expect(tileTitles(tester), ['A1', 'B1']);
    // 拖 A1（组 0）到 B1（组 1）之下 → 跨组 → 忽略。
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('A1')));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(const Offset(0, 300));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // sortOrder 保持原值（reorder() 未被调用）；视图顺序未变。
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b]))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    expect({for (final r in rows) r.id: r.sortOrder}, {a: 5, b: 9});
    expect(tileTitles(tester), ['A1', 'B1']);
    await env.db.close();
  });

  testWidgets('组头无拖拽监听且拖动组头不产生变化', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'A1', 'next_action');
    await insertTask(env, 'B1', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(
      _anytimeProvider,
      reorderEnabled: true,
      groupKey: _groupOf,
      buildDateHeader: _groupHeader,
    )));
    await tester.pump();
    // 组头不被任何拖拽监听包裹（Delayed 是 DragStart 的子类，byType 一并命中；
    // 行会被包，组头不会）。
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('task_header_0')),
        matching: find.byType(ReorderableDragStartListener),
      ),
      findsNothing,
    );
    // 拖动组头：无监听 → 无重排、无落库。
    final before = await (env.db.select(env.db.tasks)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Group 0')));
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    final after = await (env.db.select(env.db.tasks)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    expect(after.map((r) => r.title).toList(), before.map((r) => r.title).toList());
    expect(tileTitles(tester), ['A1', 'B1']);
    await env.db.close();
  });

  testWidgets('onAction 未注入：组件默认处理批量动作（选中后按钮可点）', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    final completeBtn = tester.widget<IconButton>(
      find.byKey(const Key('task_selection_action_complete')),
    );
    // Task 2 起组件内置默认处理：选中即可点（不再依赖 onAction 注入）。
    expect(completeBtn.onPressed == null, isFalse);
    await env.db.close();
  });

  testWidgets('组内拖至组首：非首组任务拖到该组顶部槽位，reorder() 落库', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'A1', 'next_action');
    await insertTask(env, 'B0', 'next_action');
    await insertTask(env, 'B1', 'next_action');
    await insertTask(env, 'B2', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(
      _anytimeProvider,
      reorderEnabled: true,
      groupKey: _groupOf,
      buildDateHeader: _groupHeader,
    )));
    await tester.pump();
    expect(tileTitles(tester), ['A1', 'B0', 'B1', 'B2']);
    // B 组顶部槽位 = 「Group 1」组头正下方第一槽。落点取 B0 行中心偏下 10px：
    // 代理行顶边落在 B0 前半段 → 框架插入位 = B0 位置（组首槽），且不触碰组头。
    final b0Center = tester.getCenter(find.text('B0'));
    final b2Center = tester.getCenter(find.text('B2'));
    final gesture = await tester.startGesture(b2Center);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(Offset(0, b0Center.dy + 10 - b2Center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // 落库：B2 排到 B 组第一（sortOrder 顺序 [A1, B2, B0, B1]）。
    final rows = await (env.db.select(env.db.tasks)
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    expect(rows.map((r) => r.title).toList(), ['A1', 'B2', 'B0', 'B1']);
    expect(tileTitles(tester), ['A1', 'B2', 'B0', 'B1']);
    await env.db.close();
  });

  testWidgets('他组拖至组首被拒绝：no-op 弹回，reorder() 不落库', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'A0', 'next_action', sortOrder: 5);
    await insertTask(env, 'A1', 'next_action', sortOrder: 9);
    await insertTask(env, 'B0', 'next_action', sortOrder: 13);
    await tester.pumpWidget(env.wrap(_Host(
      _anytimeProvider,
      reorderEnabled: true,
      groupKey: _groupOf,
      buildDateHeader: _groupHeader,
    )));
    await tester.pump();
    expect(tileTitles(tester), ['A0', 'A1', 'B0']);
    // 把 A1（组 0）拖到 B 组顶部槽位（B0 行中心偏下 10px，同上一用例的落点）。
    final b0Center = tester.getCenter(find.text('B0'));
    final a1Center = tester.getCenter(find.text('A1'));
    final gesture = await tester.startGesture(a1Center);
    await tester.pump(kLongPressTimeout + kPressTimeout);
    await gesture.moveBy(Offset(0, b0Center.dy + 10 - a1Center.dy));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    // sortOrder 保持原值（reorder() 未被调用）；视图顺序未变。
    final rows = await (env.db.select(env.db.tasks)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    expect(
      {for (final r in rows) r.title: r.sortOrder},
      {'A0': 5, 'A1': 9, 'B0': 13},
    );
    expect(tileTitles(tester), ['A0', 'A1', 'B0']);
    await env.db.close();
  });

  testWidgets('批量完成：全部 done + 重复任务各自生成下一次副本', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action',
        scheduled: DateTime(2026, 11, 26, 9), repeatRule: 'daily');
    await tester.pumpWidget(env.wrap(_Host(_nextActionProvider)));
    await tester.pump();
    // 长按 A 进选择，点选 B → 2 项。
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    await tester.tap(find.text('Task B'));
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('task_selection_action_complete')));
    await tester.pumpAndSettle();
    // 原任务全部 done；B 的每日副本 = next_action + scheduled 推进一天。
    final rows = await env.db.select(env.db.tasks).get();
    expect(rows.singleWhere((r) => r.id == a).status, 'done');
    expect(rows.singleWhere((r) => r.id == b).status, 'done');
    final clones = rows
        .where((r) => r.status == 'next_action' && r.title == 'Task B')
        .toList();
    expect(clones, hasLength(1));
    expect(clones.single.scheduled,
        DateTime(2026, 11, 27, 9).millisecondsSinceEpoch);
    expect(clones.single.repeatRule, 'daily');
    // 动作后退出选择模式。
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('批量删除：确认后全部硬删除', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    await tester.tap(find.text('Task B'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_delete')));
    await tester.pumpAndSettle();
    // 确认对话框（复用 logbook_confirm_delete Key）→ 确认。
    expect(find.byKey(const Key('logbook_confirm_delete')), findsOneWidget);
    await tester.tap(find.byKey(const Key('logbook_confirm_delete')));
    await tester.pumpAndSettle();
    final rows = await env.db.select(env.db.tasks).get();
    expect(rows.map((r) => r.id).toList(), isNot(contains(a)));
    expect(rows.map((r) => r.id).toList(), isNot(contains(b)));
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('批量删除取消：不删除、保持选择模式', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    final rows = await env.db.select(env.db.tasks).get();
    expect(rows.map((r) => r.id).toList(), [a]);
    expect(find.byKey(const Key('task_selection_bar')), findsOneWidget);
    await env.db.close();
  });

  testWidgets('批量设日期（截止）：全部写入目标日', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    await tester.tap(find.text('Task B'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_setDate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_selection_setdate_due')));
    await tester.pumpAndSettle();
    // 日期选择：initialDate = 今天，直接 OK（不点日格，与表单测试同款）。
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b])))
        .get();
    expect(rows.map((r) => r.dueDate).toList(), [today, today]);
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('批量设日期（开始）：全部写入目标日', (tester) async {
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    await tester.tap(find.text('Task B'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_setDate')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_selection_setdate_scheduled')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b])))
        .get();
    expect(rows.map((r) => r.scheduled).toList(), [today, today]);
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('批量移动：全部写入目标项目', (tester) async {
    final env = await TestEnv.create();
    final project = await env.db.into(env.db.projects).insert(
        ProjectsCompanion.insert(
            name: '客户交付', status: 'active', createdAt: 1, updatedAt: 1));
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    await tester.tap(find.text('Task B'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_move')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task_selection_move_dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('task_selection_move_project')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客户交付').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_selection_move_ok')));
    await tester.pumpAndSettle();
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b])))
        .get();
    expect(rows.map((r) => r.projectId).toList(), [project, project]);
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('日志批量恢复：全部回到 next_action', (tester) async {
    final env = await TestEnv.create();
    final a = await insertDone(env, 'Done A',
        DateTime(2026, 11, 25, 10).millisecondsSinceEpoch);
    final b = await insertDone(env, 'Done B',
        DateTime(2026, 11, 25, 11).millisecondsSinceEpoch);
    await tester.pumpWidget(env.wrap(_Host(
      _doneProvider,
      sortMode: TaskSortMode.reverseChronological,
      rowVariant: TaskRowVariant.logbook,
      actions: const [TaskListAction.restore],
    )));
    await tester.pump();
    await tester.longPress(find.text('Done A'));
    await tester.pump();
    await tester.tap(find.text('Done B'));
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);
    await tester.tap(find.byKey(const Key('task_selection_action_restore')));
    await tester.pumpAndSettle();
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b])))
        .get();
    expect(rows.map((r) => r.status).toList(), ['next_action', 'next_action']);
    expect(rows.map((r) => r.completedAt).toList(), [null, null]);
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  testWidgets('批量动作后退出选择模式：状态复位', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    expect(state.selectionMode, isTrue);
    await tester.tap(find.byKey(const Key('task_selection_action_complete')));
    await tester.pumpAndSettle();
    expect(state.selectionMode, isFalse);
    expect(state.selectedIds, isEmpty);
    expect(find.byKey(const Key('task_selection_bar')), findsNothing);
    await env.db.close();
  });

  // —— 桌面焦点快捷键（规格 §5：J/K/Enter/Delete，仅桌面 focusEnabled）——

  /// 桌面平台覆盖：widget 测试默认 Android/触屏，列表快捷键仅桌面生效。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  testWidgets('桌面焦点快捷键：J/K 上下移焦点（列表内循环）', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await insertTask(env, 'Task C', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    // 先聚焦首行（requestFocus），随后 J/K 经焦点行冒泡触发列表快捷键。
    state.focusRow(0);
    await tester.pump();
    expect(state.focusIndex, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 2);
    // 末行 J → 回绕首行。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 0);
    // 首行 K → 回绕末行。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.pump();
    expect(state.focusIndex, 2);
    await env.db.close();
  });

  testWidgets('桌面焦点快捷键：Enter 完成焦点任务', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    state.focusRow(0); // 标准排序 id 升序 → Task A。
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final row = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.equals(a)))
        .getSingle();
    expect(row.status, 'done');
    expect(find.text('Task A'), findsNothing);
    await env.db.close();
  });

  testWidgets('桌面焦点快捷键：Delete 删除焦点任务（确认对话框）', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    state.focusRow(0);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    // 确认对话框（复用 logbook_confirm_delete Key）→ 确认后硬删除。
    expect(find.byKey(const Key('logbook_confirm_delete')), findsOneWidget);
    await tester.tap(find.byKey(const Key('logbook_confirm_delete')));
    await tester.pumpAndSettle();
    final rows =
        await (env.db.select(env.db.tasks)..where((t) => t.id.equals(a))).get();
    expect(rows, isEmpty);
    expect(find.text('Task A'), findsNothing);
    await env.db.close();
  });

  testWidgets('长列表 J 推进：焦点行滚动跟随可见，Enter 作用于可见焦点行（I-1）',
      (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final ids = <int>[];
    for (var i = 0; i < 30; i++) {
      ids.add(await insertTask(env, 'Task $i', 'next_action'));
    }
    // 视口 600px：30 行 >> 可见行数，J 推进必然越过屏外行。
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    const target = 25;
    state.focusRow(0);
    await tester.pump();
    for (var i = 0; i < target; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
      await tester.pumpAndSettle(); // 等 ensureVisible 滚动动画结束。
    }
    expect(state.focusIndex, target);
    // a) 焦点行高亮在可见区（视口内）——屏外行不会被误聚焦。
    final listRect = tester.getRect(find.byType(ListView));
    final rowRect = tester.getRect(find.byKey(Key('task_focus_${ids[target]}')));
    expect(rowRect.top, greaterThanOrEqualTo(listRect.top));
    expect(rowRect.bottom, lessThanOrEqualTo(listRect.bottom));
    // b) Enter 完成 = 当前可见焦点行；屏外首行不被误完成。
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final done = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.equals(ids[target])))
        .getSingle();
    expect(done.status, 'done');
    final first = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.equals(ids[0])))
        .getSingle();
    expect(first.status, 'next_action');
    await env.db.close();
  });

  testWidgets('移动端（非桌面）：J 不移动焦点（快捷键仅桌面启用，M-3）',
      (tester) async {
    // 不调 useDesktop()：widget 测试默认 Android/触屏，列表快捷键不包裹。
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    // 焦点行包装与平台无关（focusEnabled 即有），仅快捷键被门控在桌面外。
    state.focusRow(0);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 0);
    await env.db.close();
  });

  testWidgets('选择模式阻断列表快捷键：J 不移动、Delete 不弹确认框（M-7）',
      (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    state.focusRow(0);
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    expect(find.byKey(const Key('task_selection_bar')), findsOneWidget);
    // J 被 `_canMoveRowFocus` 门控拦截。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 0);
    // Delete 被 `_canOperateRow` 门控拦截（不弹确认对话框）。
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logbook_confirm_delete')), findsNothing);
    await env.db.close();
  });

  testWidgets('行内控件获焦阻断列表快捷键：Enter 不完成焦点任务（M-7）',
      (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final a = await insertTask(env, 'Task A', 'next_action');
    final b = await insertTask(env, 'Task B', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    // 焦点在第 2 行（Task B），Shift+Tab 回退到第 1 行（Task A）的行内控件
    // （完成钮/行 InkWell），使 focusedTask（B）与获焦控件（A 的行内控件）
    // 分离——若门控缺失，Enter 会经快捷键完成看不见/错误的 B。
    state.focusRow(1);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    // 前置断言：primary focus 已离开焦点行节点（落在行内控件上）。
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      isNot(startsWith('task_focus_')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // 门控生效：B（focusedTask）必须仍为 next_action；行内控件自身的 Enter
    // 激活只会作用于它自己的任务（A，完成钮）或打开编辑框（行 InkWell）。
    final rows = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.isIn([a, b])))
        .get();
    expect(rows.singleWhere((r) => r.id == b).status, 'next_action');
    await env.db.close();
  });
}
