import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
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
}
