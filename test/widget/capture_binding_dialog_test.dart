import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/features/settings/shortcuts/capture_binding_dialog.dart';
import 'widget_utils.dart';

void main() {
  /// 弹窗宿主：按钮点开 CaptureBindingDialog（collect 动作）。
  Future<TestEnv> pumpDialog(WidgetTester tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const CaptureBindingDialog(actionId: 'collect'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return env;
  }

  /// 发送完整 down/up 序列（避免硬件键盘状态泄漏）。
  Future<void> sendChord(WidgetTester tester,
      {bool ctrl = false, bool shift = false, bool meta = false}) async {
    if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    if (meta) await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    if (meta) await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('录键成功：Ctrl+Shift+A → 弹窗关闭 + 绑定生效', (tester) async {
    final env = await pumpDialog(tester);
    await sendChord(tester, ctrl: true, shift: true);
    await tester.pumpAndSettle();
    expect(find.byType(CaptureBindingDialog), findsNothing);
    final saved = env.prefs.getString('shortcut_bindings');
    // jsonEncode 输出紧凑 JSON（冒号后无空格），按实际存储形断言。
    expect(saved, contains('"key":"KeyA"'));
    expect(saved, contains('"control":true'));
    expect(saved, contains('"shift":true'));
    await env.db.close();
  });

  testWidgets('Esc 取消：弹窗关闭 + 状态不变', (tester) async {
    final env = await pumpDialog(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CaptureBindingDialog), findsNothing);
    expect(env.prefs.getString('shortcut_bindings'), isNull);
    await env.db.close();
  });

  testWidgets('含 Esc 组合取消：Ctrl+Esc 亦取消', (tester) async {
    final env = await pumpDialog(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(CaptureBindingDialog), findsNothing);
    expect(env.prefs.getString('shortcut_bindings'), isNull);
    await env.db.close();
  });

  testWidgets('冲突拒绝：navInbox 预占 Ctrl+T → 录 Ctrl+T 显占用名，弹窗未关',
      (tester) async {
    final env = await TestEnv.create();
    await env.prefs.setString('shortcut_bindings',
        '{"navInbox": {"key": "KeyT", "control": true}}');
    await tester.pumpWidget(env.wrap(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const CaptureBindingDialog(actionId: 'collect'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // 预置绑定在控制器构造（pump 时）读入。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.byType(CaptureBindingDialog), findsOneWidget);
    expect(find.text('This shortcut is already used by Inbox'), findsOneWidget);
    // 冲突未保存：bindingFor('collect') 仍为默认 KeyN。
    expect(env.prefs.getString('shortcut_bindings'),
        '{"navInbox": {"key": "KeyT", "control": true}}');
    await env.db.close();
  });

  testWidgets('纯修饰键忽略：只按 Shift → 提示可见，弹窗未关', (tester) async {
    final env = await pumpDialog(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(find.byType(CaptureBindingDialog), findsOneWidget);
    expect(find.text('Include at least one non-modifier key'), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await env.db.close();
  });
}
