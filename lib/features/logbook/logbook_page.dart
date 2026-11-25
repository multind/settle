import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';

/// 日志视图（index 8，占位）：Task 5 填充 `watchDone` 归档/搜索/恢复/删除。
class LogbookPage extends StatelessWidget {
  const LogbookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLogbook)),
      body: Center(child: Text(l10n.navLogbook)),
    );
  }
}
