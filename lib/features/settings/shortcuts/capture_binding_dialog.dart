import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/core/shortcuts/shortcut_bindings.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'shortcut_labels.dart';

/// 录键弹窗（桌面设置 spec 功能一 §7）：模态，内嵌 Focus(autofocus) 捕获键盘。
/// 在独立 Overlay 路由内获焦，按键沿 Overlay/Navigator 祖先链冒泡，不进入
/// 壳层 Shortcuts 子树（与收集弹窗同款隔离，弹窗内按键不与应用快捷键互扰）。
/// Esc（含组合）取消；纯修饰键提示；冲突拒绝显示占用动作名；成功即关。
class CaptureBindingDialog extends ConsumerStatefulWidget {
  const CaptureBindingDialog({super.key, required this.actionId});

  /// 配置哪个动作（spec 动作表 id，如 'collect'）。
  final String actionId;

  @override
  ConsumerState<CaptureBindingDialog> createState() =>
      _CaptureBindingDialogState();
}

class _CaptureBindingDialogState extends ConsumerState<CaptureBindingDialog> {
  /// 状态行文案：冲突/纯修饰键提示；初始为空（不显示）。
  String _status = '';

  static bool _isModifier(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.metaLeft ||
      key == LogicalKeyboardKey.metaRight ||
      key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight ||
      key == LogicalKeyboardKey.altLeft ||
      key == LogicalKeyboardKey.altRight;

  KeyEventResult _handleKey(LogicalKeyboardKey logicalKey) {
    final l10n = AppLocalizations.of(context)!;
    // Esc 保留为取消键（含 Ctrl+Esc 等组合），不可被捕获。
    if (logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final control = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final meta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    final shift = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    final alt = pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight);
    // 主键为修饰键且当前按住的全是修饰键 → 提示继续等待（Ctrl+Shift 亦属此类）。
    if (_isModifier(logicalKey) && !pressed.any((k) => !_isModifier(k))) {
      setState(() => _status = l10n.captureModifiersOnlyHint);
      return KeyEventResult.handled;
    }
    final String keyName;
    try {
      keyName = keyNameOf(logicalKey);
    } on FormatException {
      return KeyEventResult.handled; // 不可序列化键（媒体键等）：忽略保持等待。
    }
    final binding = ShortcutBinding(
      key: keyName,
      control: control,
      meta: meta,
      shift: shift,
      alt: alt,
    );
    final conflictId = ref
        .read(shortcutSettingsControllerProvider)
        .trySetBinding(widget.actionId, binding);
    if (conflictId == null) {
      Navigator.of(context).pop(); // 成功：关闭，页面经 watch 自动刷新键帽。
    } else {
      final conflictAction = actionById(conflictId);
      setState(() => _status =
          l10n.captureConflict(actionLabel(l10n, conflictAction.labelKey)));
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = actionById(widget.actionId);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return AlertDialog(
      title: Text(actionLabel(l10n, action.labelKey)),
      content: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // 自动重复在本 SDK 以 KeyRepeatEvent 抵达（KeyDownEvent.repeat 已移除），
          // `is! KeyDownEvent` 即已排除重复事件。
          if (event is! KeyDownEvent) {
            return KeyEventResult.ignored;
          }
          return _handleKey(event.logicalKey);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.capturePrompt),
            const SizedBox(height: 4),
            Text(
              l10n.captureEscHint,
              style: TextStyle(fontSize: 12, color: tokens.muted),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _status,
                style: TextStyle(fontSize: 13, color: tokens.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
