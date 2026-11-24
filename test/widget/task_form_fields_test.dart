import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/task/task_form_fields.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('标题必填校验；空标题 validate 返回 null（验收④）', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await tester.pumpWidget(env.wrap(_FormHost(formKey: formKey)));
    await tester.tap(find.byKey(const Key('validate_button')));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isNull);
    // drift 内部用 Timer 延迟清理流缓存；须在测试体结束前关闭数据库
    // （drift 官方：Flutter widget test 中请调用并 await Database.close()）。
    await env.db.close();
  });

  testWidgets('等待任务必须填等待对象（规格 §5.2）', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await tester.pumpWidget(env.wrap(_FormHost(formKey: formKey)));
    await tester.enterText(find.byKey(const Key('task_title_field')), '跟进报销');
    await tester.tap(find.byKey(const Key('task_status_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waiting').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('validate_button')));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate(), isNull);
    // 填上等待对象后可校验通过
    await tester.enterText(find.byKey(const Key('task_waiting_on_field')), '财务部');
    final draft = formKey.currentState!.validate();
    expect(draft, isNotNull);
    expect(draft!.status, TaskStatus.waiting);
    expect(draft.waitingOn, '财务部');
    await env.db.close();
  });

  testWidgets('创建草稿携带全部字段（验收④）', (tester) async {
    final env = await TestEnv.create();
    final project = await env.db.into(env.db.projects).insert(
        ProjectsCompanion.insert(name: '客户交付', status: 'active', createdAt: 1, updatedAt: 1));
    final context = await env.db.into(env.db.contexts).insert(
        ContextsCompanion.insert(name: '@电脑', sort: const Value(0)));
    final tag = await env.db.into(env.db.tags).insert(
        TagsCompanion.insert(name: '客户', color: '#1A73E8'));
    final formKey = GlobalKey<TaskFormFieldsState>();
    await tester.pumpWidget(env.wrap(_FormHost(formKey: formKey)));
    await tester.enterText(find.byKey(const Key('task_title_field')), '写方案');
    await tester.enterText(find.byKey(const Key('task_notes_field')), '备注');
    await tester.tap(find.byKey(const Key('task_priority_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('high').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_energy_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('medium').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_project_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客户交付').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task_context_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('@电脑').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('tag_chip_$tag')));
    await tester.pumpAndSettle();
    final draft = formKey.currentState!.validate();
    expect(draft!.title, '写方案');
    expect(draft.notes, '备注');
    expect(draft.priority, PriorityLevel.high);
    expect(draft.energy, EnergyLevel.medium);
    expect(draft.projectId, project);
    expect(draft.contextId, context);
    expect(draft.tagIds, {tag});
    await env.db.close();
  });
}

class _FormHost extends StatefulWidget {
  const _FormHost({required this.formKey});
  final GlobalKey<TaskFormFieldsState> formKey;
  @override
  State<_FormHost> createState() => _FormHostState();
}

class _FormHostState extends State<_FormHost> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(
          children: [
            TaskFormFields(key: widget.formKey),
            FilledButton(
              key: const Key('validate_button'),
              onPressed: () => setState(() {}),
              child: const Text('validate'),
            ),
          ],
        ),
      );
}
