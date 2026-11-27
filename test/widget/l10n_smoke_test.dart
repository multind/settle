import 'package:flutter/material.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('zh locale loads Chinese nav strings', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(l10n.navInbox);
      }),
    ));
    expect(find.text('收件箱'), findsOneWidget);
    expect(AppLocalizations.of(tester.element(find.byType(Text)))!.navToday, '今日');
  });

  testWidgets('en locale loads English nav strings', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        return Text(AppLocalizations.of(context)!.navInbox);
      }),
    ));
    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgets('guide keys load in zh and en', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(
            '${l10n.navGuide}|${l10n.ruleInboxTitle}|${l10n.ruleInboxMessage}|${l10n.onboardingOpenGuide}');
      }),
    ));
    expect(
      find.text('GTD 指南|只收集，不整理|每条以动词开头，写清下一步动作。|查看完整指南 →'),
      findsOneWidget,
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(
            '${l10n.navGuide}|${l10n.ruleInboxTitle}|${l10n.ruleInboxMessage}|${l10n.onboardingOpenGuide}');
      }),
    ));
    expect(
      find.text('GTD Guide|Collect, don\'t organize|Start each item with a verb and state the next action.|View the full guide →'),
      findsOneWidget,
    );
  });

  testWidgets('desktop settings keys load in zh and en', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(
            '${l10n.settingsShortcuts}|${l10n.settingsAlwaysOnTop}|${l10n.actionCollect}|${l10n.actionToggleAlwaysOnTop}|${l10n.capturePrompt}|${l10n.captureConflict('收件箱')}|${l10n.keyCtrl}');
      }),
    ));
    expect(
      find.text('快捷键|窗口置顶|收集|切换窗口置顶|按下新快捷键…|该快捷键已被 收件箱 占用|Ctrl'),
      findsOneWidget,
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(
            '${l10n.settingsShortcuts}|${l10n.settingsAlwaysOnTop}|${l10n.actionCollect}|${l10n.actionToggleAlwaysOnTop}|${l10n.capturePrompt}|${l10n.captureConflict('Inbox')}|${l10n.keyCtrl}');
      }),
    ));
    expect(
      find.text('Keyboard Shortcuts|Always on Top|Collect|Toggle Always on Top|Press new shortcut…|This shortcut is already used by Inbox|Ctrl'),
      findsOneWidget,
    );
  });
}
