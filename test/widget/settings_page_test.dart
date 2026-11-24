import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/data/tables.dart';
import 'package:gtd_app/features/settings/settings_page.dart';
import 'widget_utils.dart';

void main() {
  testWidgets('语言切换写入偏好设置（验收⑦⑧）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pumpAndSettle();
    expect(env.prefs.getString('locale'), 'zh');
    await tester.tap(find.byKey(const Key('locale_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(env.prefs.getString('locale'), 'en');
  });

  testWidgets('导出触发 Fake 网关并保存全库 JSON（验收⑦）', (tester) async {
    final env = await TestEnv.create();
    await env.db.into(env.db.inboxItems).insert(InboxItemsCompanion.insert(
      rawText: 'x',
      source: 'text',
      status: 'pending',
      createdAt: 1,
      updatedAt: 1,
    ));
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('export_backup_tile')));
    await tester.pumpAndSettle();
    final map = await env.decodeSavedJson();
    expect(map['app'], 'gtd');
    expect(map['inbox_items'], hasLength(1));
  });

  testWidgets('恢复：Fake 返回 JSON 后数据入库（验收⑦）', (tester) async {
    final env = await TestEnv.create();
    env.backup.pickedJson = '{"app":"gtd","version":1,"exported_at":1,'
        '"inbox_items":[],"projects":[],'
        '"contexts":[{"id":1,"name":"@电脑","icon":null,"sort":0}],'
        '"tags":[],"tasks":[],"task_tags":[],"reviews":[]}';
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('import_backup_tile')));
    await tester.pumpAndSettle();
    expect(await env.db.select(env.db.contexts).get(), hasLength(1));
  });

  testWidgets('恢复非法备份提示无效且不动数据（§9.1）', (tester) async {
    final env = await TestEnv.create();
    env.backup.pickedJson = '{"app":"x"}';
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    await tester.tap(find.byKey(const Key('import_backup_tile')));
    await tester.pumpAndSettle();
    expect(find.text('Invalid backup file'), findsOneWidget);
    expect(await env.db.select(env.db.contexts).get(), hasLength(3));
  });

  testWidgets('AI 模型配置为占位入口（M1 范围，规格 §8.1）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const SettingsPage()));
    expect(find.text('AI model config (available in M2)'), findsOneWidget);
  });
}
