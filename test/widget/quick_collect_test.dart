import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/features/inbox/collect_dialog.dart';
import 'package:settle_app/features/inbox/quick_collect_bar.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('快速收集框：输入→添加→入库并提示（验收②）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const _CollectBarHost()));
    await tester.enterText(find.byKey(const Key('quick_collect_field')), '写周报');
    await tester.tap(find.byKey(const Key('quick_collect_button')));
    await tester.pumpAndSettle();
    expect(find.text('Collect'), findsOneWidget); // SnackBar 提示
    final rows = await env.db.select(env.db.inboxItems).get();
    expect(rows, hasLength(1));
    expect(rows.single.rawText, '写周报');
    expect(rows.single.source, 'text');
    expect(rows.single.status, 'pending');
  });

  testWidgets('空输入不产生条目', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const _CollectBarHost()));
    await tester.tap(find.byKey(const Key('quick_collect_button')));
    await tester.pump();
    expect(await env.db.select(env.db.inboxItems).get(), isEmpty);
  });

  testWidgets('全局收集对话框：从其他页 1 步收集（验收②）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const _CollectHost()));
    await tester.tap(find.byKey(const Key('open_collect')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('collect_dialog_field')), '买牛奶');
    await tester.tap(find.byKey(const Key('collect_dialog_submit')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), hasLength(1));
    expect(find.byType(CollectDialog), findsNothing);
  });
}

/// 顶栏快速收集框宿主（InboxPage 在 Task 22 才创建，此处仅测 QuickCollectBar 本身）。
class _CollectBarHost extends StatelessWidget {
  const _CollectBarHost();
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Column(children: const [QuickCollectBar()]));
}

class _CollectHost extends StatelessWidget {
  const _CollectHost();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: const Key('open_collect'),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const CollectDialog(),
            ),
            child: const Text('open'),
          ),
        ),
      );
}
