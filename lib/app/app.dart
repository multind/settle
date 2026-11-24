import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/app/responsive_shell.dart';
import 'package:gtd_app/app/spot_background.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/features/settings/settings_controller.dart';

/// 整应用入口（规格 §7.1 / §7.4）：双主题跟随系统 + 光斑背景垫底 + 响应式外壳。
class GtdApp extends ConsumerWidget {
  const GtdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(settingsControllerProvider);
    return MaterialApp(
      title: 'GTD',
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: selection.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      builder: (context, child) => Stack(
        children: [
          const Positioned.fill(child: SpotBackground()),
          if (child != null) child,
        ],
      ),
      home: const ResponsiveShell(),
    );
  }
}
