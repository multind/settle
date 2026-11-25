import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 随时视图（index 3，占位）：Task 3 填充 `watchAnytime` 真实现。
class AnytimePage extends StatelessWidget {
  const AnytimePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAnytime)),
      body: Center(child: Text(l10n.navAnytime)),
    );
  }
}
