import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 即将视图（index 2，占位）：Task 4 填充 `watchUpcoming` 日期分组真实现。
class UpcomingPage extends StatelessWidget {
  const UpcomingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navUpcoming)),
      body: Center(child: Text(l10n.navUpcoming)),
    );
  }
}
