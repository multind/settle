import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/features/anytime/anytime_page.dart';
import 'package:settle_app/features/contexts/contexts_page.dart';
import 'package:settle_app/features/inbox/inbox_page.dart';
import 'package:settle_app/features/logbook/logbook_page.dart';
import 'package:settle_app/features/projects/projects_page.dart';
import 'package:settle_app/features/review/review_page.dart';
import 'package:settle_app/features/someday/someday_page.dart';
import 'package:settle_app/features/today/today_page.dart';
import 'package:settle_app/features/upcoming/upcoming_page.dart';
import 'package:settle_app/features/waiting/waiting_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('10 页空态显示对应规则提示（en 默认 locale）', (tester) async {
    final env = await TestEnv.create();
    // 情境页默认种子 3 情境（@电脑/@外出/@电话），先清空再断言空态；
    // 其余页默认空库即可（与各页既有空态测试同口径）。
    await env.db.delete(env.db.contexts).go();
    final cases = <(String, String, Widget Function())>[
      ('Collect, don\'t organize',
          'Start each item with a verb and state the next action.',
          () => const InboxPage()),
      ('Today is 1-3-5',
          'Keep 1 big, 3 medium, and 5 small tasks. Add more only after finishing.',
          () => const TodayPage()),
      ('Hard time only',
          'Keep meetings and deadlines here. Drag a task onto a date header to schedule it.',
          () => const UpcomingPage()),
      ('Do anytime',
          'Tasks you\'ll do soon, without a fixed day, live here.',
          () => const AnytimePage()),
      ('Maybe later',
          'Not now, maybe later — take a look during the weekly review.',
          () => const SomedayPage()),
      ('Every project needs a next action',
          'Give each project a concrete next action and a specific goal.',
          () => const ProjectsPage()),
      ('Filter by context',
          'Filter by place or mood — @work, @home — and do what fits where you are.',
          () => const ContextsPage()),
      ('Set a follow-up date',
          'Every waiting item needs a follow-up date; scan today\'s due follow-ups every day.',
          () => const WaitingPage()),
      ('Done stays here',
          'Completed tasks are kept automatically — count them at your weekly review.',
          () => const LogbookPage()),
      ('20 minutes, every week',
          'Empty the inbox, follow up on waiting, advance projects, activate somedays, and check for hard-time conflicts.',
          () => const ReviewPage()),
    ];
    for (final c in cases) {
      await tester.pumpWidget(env.wrap(c.$3()));
      await tester.pump();
      expect(find.byKey(const Key('page_rule_hint')), findsOneWidget,
          reason: '${c.$1} 页空态应显示 PageRuleHint');
      expect(find.text(c.$1), findsOneWidget);
      expect(find.text(c.$2), findsOneWidget);
    }
    await env.db.close();
  });

  testWidgets('中英双语抽查：收件箱（en/zh）与回顾（zh）', (tester) async {
    final env = await TestEnv.create();
    // en
    await tester.pumpWidget(env.wrap(const InboxPage()));
    await tester.pump();
    expect(find.text('Collect, don\'t organize'), findsOneWidget);
    // zh 收件箱
    await tester.pumpWidget(
        env.wrap(const InboxPage(), locale: const Locale('zh')));
    await tester.pump();
    expect(find.text('只收集，不整理'), findsOneWidget);
    expect(find.text('每条以动词开头，写清下一步动作。'), findsOneWidget);
    // zh 回顾
    await tester.pumpWidget(
        env.wrap(const ReviewPage(), locale: const Locale('zh')));
    await tester.pump();
    expect(find.text('每周一次，20 分钟'), findsOneWidget);
    expect(
        find.text('清空收集箱、跟进等待、推进项目下一步、激活将来、检查硬时间冲突。'),
        findsOneWidget);
    await env.db.close();
  });
}
