import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/features/review/review_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('新建回顾：填总结与统计并保存（验收⑥）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ReviewPage()));
    await tester.tap(find.byKey(const Key('new_review_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('review_summary_field')), '本周专注客户交付');
    await tester.enterText(find.byKey(const Key('review_done_field')), '3');
    await tester.enterText(find.byKey(const Key('review_new_field')), '2');
    await tester.enterText(find.byKey(const Key('review_stalled_field')), '1');
    await tester.tap(find.byKey(const Key('review_save')));
    await tester.pumpAndSettle();
    final rows = await env.db.select(env.db.reviews).get();
    expect(rows, hasLength(1));
    expect(rows.single.summary, '本周专注客户交付');
    expect(rows.single.stats, '{"done":3,"new":2,"stalled":1}');
    expect(find.text('本周专注客户交付'), findsOneWidget);
    expect(find.text('D:3 N:2 S:1'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('统计非法输入不落库', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ReviewPage()));
    await tester.tap(find.byKey(const Key('new_review_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('review_done_field')), 'abc');
    await tester.tap(find.byKey(const Key('review_save')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.reviews).get(), isEmpty);
    await env.db.close();
  });
}
