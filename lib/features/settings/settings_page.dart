import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/features/settings/backup_file_gateway.dart';
import 'package:gtd_app/features/settings/settings_controller.dart';

/// 设置页（验收⑦⑧）：语言切换、全库 JSON 导出/恢复、AI 模型配置占位（M2 填充）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selection = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<LocaleSelection>(
              key: const Key('locale_dropdown'),
              value: selection,
              items: [
                DropdownMenuItem(
                  value: LocaleSelection.system,
                  child: Text(l10n.langSystem),
                ),
                const DropdownMenuItem(
                  value: LocaleSelection.zh,
                  child: Text('中文'),
                ),
                const DropdownMenuItem(
                  value: LocaleSelection.en,
                  child: Text('English'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  ref.read(settingsControllerProvider.notifier).setLocale(v);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            enabled: false,
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.aiPlaceholder),
          ),
          const Divider(),
          ListTile(
            key: const Key('export_backup_tile'),
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(l10n.exportBackup),
            onTap: () => _export(context, ref, l10n),
          ),
          ListTile(
            key: const Key('import_backup_tile'),
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l10n.importBackup),
            onTap: () => _import(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final json = await ref.read(exportServiceProvider).exportJson();
    final gateway = ref.read(backupFileGatewayProvider);
    final path = await gateway.saveBackup(json);
    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportedTo)),
      );
    }
  }

  Future<void> _import(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final gateway = ref.read(backupFileGatewayProvider);
    final json = await gateway.pickBackupJson();
    if (json == null) return;
    try {
      await ref.read(exportServiceProvider).importJson(json);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importedFrom)),
        );
      }
    } on FormatException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupInvalid)),
        );
      }
    }
  }
}
