import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'widget_utils.dart';

/// 文件级私有 StreamProvider（仓库测试惯例）：实时喂 TaskListView 的任务。
final _anytimeProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchAnytime());

/// 测试宿主（与 task_list_view_test 同款）：watch provider 喂数据给
/// TaskListView；焦点快捷键用例依赖 focusEnabled（恒 true）。
class _Host extends ConsumerWidget {
  const _Host(this.provider);

  final StreamProvider<List<Task>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(provider).value ?? const <Task>[];
    return Scaffold(
      body: TaskListView(
        tasks: tasks,
        selectionEnabled: true,
        focusEnabled: true,
      ),
    );
  }
}

void main() {
  /// 桌面平台覆盖：widget 测试默认 Android/触屏，列表快捷键仅桌面启用。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  Future<int> insertTask(TestEnv env, String title, String status) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
          title: title,
          status: status,
          createdAt: 1,
          updatedAt: 1,
        ));
  }

  testWidgets('rebind J→W：按 W 焦点上移生效，按 J 焦点不动', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await env.prefs.setString(
        'shortcut_bindings', jsonEncode({'listMoveUp': {'key': 'KeyW'}}));
    await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await insertTask(env, 'Task C', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    state.focusRow(0);
    await tester.pump();
    expect(state.focusIndex, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pump();
    expect(state.focusIndex, 1);
    // J 原绑定已迁移 → 焦点不动。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 1);
    await env.db.close();
  });
}
