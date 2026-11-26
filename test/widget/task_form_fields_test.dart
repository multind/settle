import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/core/models/task_draft.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/task/task_form_fields.dart';
import 'widget_utils.dart';

void main() {
  // 表单新增重复/提醒后变长：用更高的测试画布保证底部控件可命中。
  Future<void> pumpForm(
    WidgetTester tester,
    TestEnv env,
    GlobalKey<TaskFormFieldsState> formKey, {
    TaskDraft? initial,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(_FormHost(formKey: formKey, initial: initial)));
    await tester.pump();
  }

  String p2(int n) => n.toString().padLeft(2, '0');

  /// 用例均从「无初始值」进入，DatePicker 的 initialDate 默认今天：直接连点两次 OK
  /// （确认今天日期 + 确认默认 09:00 时间）。不点击日历日格——今天为每月 1~7 日时，
  /// 网格尾部渲染的下月首格同号数字会被 `.last` 静默选中（12 月跨年更是硬失败）。
  Future<void> pickTodayAt0900(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('标题必填校验；空标题 validate 返回 null（验收④）', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(tester, env, formKey);
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
    await pumpForm(tester, env, formKey);
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
    await pumpForm(tester, env, formKey);
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
    // v0.3 新字段默认不携带
    expect(draft.repeatRule, isNull);
    expect(draft.reminderAt, isNull);
    await env.db.close();
  });

  // —— v0.3 调度：截止/计划 日期+时间 ——

  testWidgets('截止日：选日期后弹时间选择，输出带时分（默认 09:00）', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(tester, env, formKey);
    await tester.enterText(find.byKey(const Key('task_title_field')), '任务');
    await tester.tap(find.text('Due date'));
    await tester.pumpAndSettle();
    await pickTodayAt0900(tester);
    final draft = formKey.currentState!.validate();
    expect(draft, isNotNull);
    final d = draft!.dueDate;
    expect(d, isNotNull);
    final now = DateTime.now();
    expect(d!.year, now.year);
    expect(d.month, now.month);
    expect(d.day, now.day);
    expect(d.hour, 9);
    expect(d.minute, 0);
    final label = '${d.year}-${p2(d.month)}-${p2(d.day)} ${p2(d.hour)}:${p2(d.minute)}';
    expect(find.text(label), findsOneWidget);
    await env.db.close();
  });

  testWidgets('计划：同样链式选择日期+时间', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(tester, env, formKey);
    await tester.enterText(find.byKey(const Key('task_title_field')), '任务');
    await tester.tap(find.text('Scheduled'));
    await tester.pumpAndSettle();
    await pickTodayAt0900(tester);
    final draft = formKey.currentState!.validate();
    final s = draft!.scheduled!;
    final now = DateTime.now();
    expect(s.year, now.year);
    expect(s.month, now.month);
    expect(s.day, now.day);
    expect(s.hour, 9);
    expect(s.minute, 0);
    await env.db.close();
  });

  testWidgets('清除按钮清空截止日/计划字段', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(tester, env, formKey);
    await tester.enterText(find.byKey(const Key('task_title_field')), '任务');
    // 截止日
    await tester.tap(find.text('Due date'));
    await tester.pumpAndSettle();
    await pickTodayAt0900(tester);
    expect(find.byKey(const Key('clear_due')), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear_due')));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate()!.dueDate, isNull);
    // 计划
    await tester.tap(find.text('Scheduled'));
    await tester.pumpAndSettle();
    await pickTodayAt0900(tester);
    expect(find.byKey(const Key('clear_scheduled')), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear_scheduled')));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate()!.scheduled, isNull);
    await env.db.close();
  });

  // —— v0.3 调度：重复 ——

  testWidgets('重复下拉各值写入 repeatRule', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(tester, env, formKey);
    await tester.enterText(find.byKey(const Key('task_title_field')), '任务');
    const cases = <String, String?>{
      'None': null,
      'Daily': 'daily',
      'Weekly': 'weekly',
      'Monthly': 'monthly',
    };
    for (final entry in cases.entries) {
      await tester.tap(find.byKey(const Key('task_repeat_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(entry.key).last);
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate()!.repeatRule, entry.value);
    }
    await env.db.close();
  });

  testWidgets('每 N 天：非法 N 拒绝，合法 N 合成 every:N', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(tester, env, formKey);
    await tester.enterText(find.byKey(const Key('task_title_field')), '任务');
    await tester.tap(find.byKey(const Key('task_repeat_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Every N days').last);
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('task_repeat_interval'));
    expect(field, findsOneWidget);
    for (final bad in ['0', '-1', 'abc', '366']) {
      await tester.enterText(field, bad);
      expect(formKey.currentState!.validate(), isNull);
    }
    await tester.enterText(field, '3');
    final draft = formKey.currentState!.validate();
    expect(draft, isNotNull);
    expect(draft!.repeatRule, 'every:3');
    await env.db.close();
  });

  testWidgets('初始 repeatRule 反解析回下拉态（every:N 回填间隔）', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(
      tester,
      env,
      formKey,
      initial: TaskDraft(
        title: '任务',
        repeatRule: 'every:5',
        dueDate: DateTime(2026, 11, 30, 8, 15),
        reminderAt: DateTime(2026, 12, 1, 10, 30),
      ),
    );
    // every:N → 出现间隔输入框并回填 N
    final interval =
        tester.widget<TextFormField>(find.byKey(const Key('task_repeat_interval')));
    expect(interval.controller!.text, '5');
    // 已有日期/提醒以 yyyy-MM-dd HH:mm 展示
    expect(find.text('2026-11-30 08:15'), findsOneWidget);
    expect(find.text('2026-12-01 10:30'), findsOneWidget);
    final draft = formKey.currentState!.validate();
    expect(draft!.repeatRule, 'every:5');
    expect(draft.dueDate, DateTime(2026, 11, 30, 8, 15));
    expect(draft.reminderAt, DateTime(2026, 12, 1, 10, 30));
    await env.db.close();
  });

  testWidgets('非法 every:N（0/非数字/超界）反解析回退「无」', (tester) async {
    final env = await TestEnv.create();
    for (final bad in ['every:0', 'every:abc', 'every:999']) {
      final formKey = GlobalKey<TaskFormFieldsState>();
      await pumpForm(
        tester,
        env,
        formKey,
        initial: TaskDraft(title: '任务', repeatRule: bad),
      );
      // 回退「无」：不出现间隔输入框，草稿不携带 repeatRule
      expect(find.byKey(const Key('task_repeat_interval')), findsNothing);
      expect(formKey.currentState!.validate()!.repeatRule, isNull);
    }
    await env.db.close();
  });

  // —— v0.3 调度：提醒 ——

  testWidgets('提醒：选择与清除', (tester) async {
    final env = await TestEnv.create();
    final formKey = GlobalKey<TaskFormFieldsState>();
    await pumpForm(tester, env, formKey);
    await tester.enterText(find.byKey(const Key('task_title_field')), '任务');
    await tester.tap(find.byKey(const Key('task_reminder_field')));
    await tester.pumpAndSettle();
    await pickTodayAt0900(tester);
    final draft = formKey.currentState!.validate();
    final r = draft!.reminderAt!;
    final now = DateTime.now();
    expect(r.year, now.year);
    expect(r.month, now.month);
    expect(r.day, now.day);
    expect(r.hour, 9);
    expect(find.byKey(const Key('clear_reminder')), findsOneWidget);
    await tester.tap(find.byKey(const Key('clear_reminder')));
    await tester.pumpAndSettle();
    expect(formKey.currentState!.validate()!.reminderAt, isNull);
    await env.db.close();
  });
}

class _FormHost extends StatefulWidget {
  const _FormHost({required this.formKey, this.initial});
  final GlobalKey<TaskFormFieldsState> formKey;
  final TaskDraft? initial;
  @override
  State<_FormHost> createState() => _FormHostState();
}

class _FormHostState extends State<_FormHost> {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(
          children: [
            TaskFormFields(key: widget.formKey, initial: widget.initial),
            FilledButton(
              key: const Key('validate_button'),
              onPressed: () => setState(() {}),
              child: const Text('validate'),
            ),
          ],
        ),
      );
}
