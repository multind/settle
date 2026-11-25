import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/gestures.dart' show kLongPressTimeout, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// 测试宿主：watch 指定 provider 并把数据喂给 TaskListView（默认英文 locale）。
/// 多选/焦点恒为 true（所有用例都依赖选择可用）；重排按用例开关。
class _Host extends ConsumerWidget {
  const _Host(
    this.provider, {
    this.reorderEnabled = false,
    this.sortMode = TaskSortMode.standard,
    this.rowVariant = TaskRowVariant.standard,
    this.groupKey,
    this.buildDateHeader,
  });

  final StreamProvider<List<Task>> provider;
  final bool reorderEnabled;
  final TaskSortMode sortMode;
  final TaskRowVariant rowVariant;
  final Comparable Function(Task task)? groupKey;
  final Widget Function(BuildContext context, Comparable key)? buildDateHeader;

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
        actions: const [
          TaskListAction.complete,
          TaskListAction.delete,
          TaskListAction.setDate,
          TaskListAction.move,
        ],
      ),
    );
  }
}

/// 分组测试用宿主参数：按标题首字母分两组（'A*' → 0，其余 → 1）。
Comparable _groupOf(Task t) => t.title.startsWith('A') ? 0 : 1;

Widget _groupHeader(BuildContext context, Comparable key) => Text('Group $key');

void main() {
  Future<int> insertTask(TestEnv env, String title, String status,
      {String? priority, int? sortOrder}) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
      title: title,
      status: status,
      priority: Value(priority),
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

  testWidgets('onAction 未接线：选择栏动作按钮置灰禁用', (tester) async {
    final env = await TestEnv.create();
    await insertTask(env, 'Task A', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    await tester.longPress(find.text('Task A'));
    await tester.pump();
    final completeBtn = tester.widget<IconButton>(
      find.byKey(const Key('task_selection_action_complete')),
    );
    expect(completeBtn.onPressed, isNull);
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
}
