import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/inbox/clarify_dialog.dart';
import 'widget_utils.dart';

void main() {
  Future<int> seedItem(TestEnv env, {String text = '写周报'}) async {
    return env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: text,
      source: 'text',
      status: 'pending',
      createdAt: 1,
      updatedAt: 1,
    ));
  }

  testWidgets('确认路径：转为行动→条目 clarified 且创建 next_action 任务（验收③）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    final details = find.text('Task details');
    final notes = find.byKey(const Key('task_notes_field'));
    expect(notes, findsNothing);
    await tester.tap(details);
    await tester.pumpAndSettle();
    await tester.enterText(notes, '附上本周进度');
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(notes, findsNothing);
    await tester.enterText(find.byKey(const Key('task_title_field')), '写周报');
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    final item = await (env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'clarified');
    final tasks = await env.db.select(env.db.tasks).get();
    expect(tasks, hasLength(1));
    expect(tasks.single.title, '写周报');
    expect(tasks.single.notes, '附上本周进度');
    expect(tasks.single.status, 'next_action');
    await env.db.close();
  });

  testWidgets('转为项目→创建 active 项目并标 clarified（验收③）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env, text: '客户交付计划');
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn into project'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('clarify_project_name')), '客户交付');
    await tester.enterText(find.byKey(const Key('clarify_project_goal')), '完成交付');
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    final projects = await env.db.select(env.db.projects).get();
    expect(projects, hasLength(1));
    expect(projects.single.name, '客户交付');
    expect(projects.single.status, 'active');
    final item = await (env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'clarified');
    await env.db.close();
  });

  testWidgets('删除路径→条目硬删除（验收③/§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.inboxItems).get(), isEmpty);
    await env.db.close();
  });

  testWidgets('取消路径→不产生任何写入（验收③）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.tasks).get(), isEmpty);
    expect(await env.db.select(env.db.projects).get(), isEmpty);
    final item = await (env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'pending');
    await env.db.close();
  });

  testWidgets('转为等待任务必须填等待对象才能保存（§5.2）', (tester) async {
    final env = await TestEnv.create();
    final id = await seedItem(env);
    await tester.pumpWidget(env.wrap(_ClarifyHost(itemId: id)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open_clarify')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Task details'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_status_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waiting').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    final item = await (env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle();
    expect(item.status, 'pending'); // 校验失败，未落库
    await tester.enterText(find.byKey(const Key('task_waiting_on_field')), '财务部');
    await tester.tap(find.byKey(const Key('clarify_confirm')));
    await tester.pumpAndSettle();
    expect((await (env.db.select(env.db.inboxItems)..where((t) => t.id.equals(id))).getSingle()).status, 'clarified');
    expect((await env.db.select(env.db.tasks).get()).single.waitingOn, '财务部');
    await env.db.close();
  });
}

class _ClarifyHost extends ConsumerWidget {
  const _ClarifyHost({required this.itemId});
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FutureBuilder<InboxItem?>(
        future: ref.read(inboxRepositoryProvider).byId(itemId),
        builder: (context, snapshot) {
          final item = snapshot.data;
          if (item == null) return const SizedBox.shrink();
          return Center(
            child: FilledButton(
              key: const Key('open_clarify'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ClarifyDialog(item: item),
              ),
              child: const Text('clarify'),
            ),
          );
        },
      ),
    );
  }
}
