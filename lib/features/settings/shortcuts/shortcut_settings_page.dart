import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/core/shortcuts/shortcut_bindings.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'capture_binding_dialog.dart';
import 'shortcut_labels.dart';

/// 快捷键配置页（桌面设置 spec 功能一 §6）：两组 16 行 + 键帽 + 恢复默认。
/// 经设置页 Navigator.push 推入（模态子配置语义，与指南页外壳切页区分）。
class ShortcutSettingsPage extends ConsumerWidget {
  const ShortcutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // 订阅控制器：改绑 notify → 本页重建（行内 bindingFor 经 _row 读取）。
    ref.watch(shortcutSettingsControllerProvider);
    final bridge = ref.watch(platformBridgeProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shortcutsTitle),
        actions: [
          TextButton(
            key: const Key('shortcuts_reset'),
            onPressed: () => _confirmReset(context, ref, l10n),
            child: Text(l10n.shortcutsReset),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _groupTitle(tokens, l10n.shortcutsGroupGlobal),
          for (final action in shortcutActions
              .where((a) => a.layer == ShortcutLayer.shell))
            _row(context, ref, tokens, l10n, bridge.isMacOS, action),
          _groupTitle(tokens, l10n.shortcutsGroupList),
          for (final action in shortcutActions
              .where((a) => a.layer == ShortcutLayer.list))
            _row(context, ref, tokens, l10n, bridge.isMacOS, action),
        ],
      ),
    );
  }

  Widget _groupTitle(AppTokenSet tokens, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tokens.muted,
          ),
        ),
      );

  Widget _row(BuildContext context, WidgetRef ref, AppTokenSet tokens,
      AppLocalizations l10n, bool isMacOS, ShortcutAction action) {
    final binding = ref
        .read(shortcutSettingsControllerProvider)
        .bindingFor(action.id);
    return ListTile(
      key: Key('shortcut_row_${action.id}'),
      title: Text(actionLabel(l10n, action.labelKey)),
      trailing: _Keycap(
        tokens: tokens,
        binding: binding,
        isMacOS: isMacOS,
        l10n: l10n,
      ),
      onTap: () => _capture(context, action),
    );
  }

  Future<void> _capture(BuildContext context, ShortcutAction action) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CaptureBindingDialog(actionId: action.id),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.shortcutsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('shortcuts_reset_confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.shortcutsReset),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(shortcutSettingsControllerProvider).resetAll();
    }
  }
}

/// 键帽：1px hairline 圆角 6 小盒，修饰符符号 + 键名，'+' 拼接（spec §6）。
/// 主修饰符合并展示：meta&&!control → Cmd；control&&!meta → macOS ? Cmd : Ctrl；
/// 双真 → Ctrl+Cmd 并列；其后 Shift → Alt。纯单键绑定 → 仅键名。
class _Keycap extends StatelessWidget {
  const _Keycap({
    required this.tokens,
    required this.binding,
    required this.isMacOS,
    required this.l10n,
  });

  final AppTokenSet tokens;
  final ShortcutBinding binding;
  final bool isMacOS;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (binding.meta && !binding.control) l10n.keyCmd,
      if (binding.control && !binding.meta)
        (isMacOS ? l10n.keyCmd : l10n.keyCtrl),
      if (binding.control && binding.meta) '${l10n.keyCtrl}+${l10n.keyCmd}',
      if (binding.shift) l10n.keyShift,
      if (binding.alt) l10n.keyAlt,
      _keyLabel(binding.key),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.stroke, width: 1),
      ),
      child: Text(
        parts.join('+'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.chipText,
        ),
      ),
    );
  }
}

/// 键帽键名映射（spec §6 规则 3）：DigitN → keyLabel('N')、KeyX → keyLabel('X')
/// （SDK `LogicalKeyboardKey.keyLabel` 对可打印键返回大写字符，release 可用）；
/// Enter/Delete/Space 特判原名（与 keyLabel 同名，显式特判防未来 SDK 变更）；
/// 未知键 → 键名原样。
String _keyLabel(String keyName) {
  if (keyName == 'Enter' || keyName == 'Delete' || keyName == 'Space') {
    return keyName;
  }
  final label = logicalKeyForKeyName(keyName)?.keyLabel ?? '';
  return label.isEmpty ? keyName : label;
}
