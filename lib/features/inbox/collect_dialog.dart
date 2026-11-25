import 'package:flutter/material.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';

/// 全局快速收集对话框（shell FAB 复用，任意界面 1 步发起收集，规格 §7.3）。
///
/// 视觉（Things 3）：`GlassContainer` 为纯底描边容器（`cardSolid` 底 + `stroke`
/// 描边，圆角 8），提交按钮为 `GradientButton` 实色主按钮（primary 底 + 白字）。
class CollectDialog extends ConsumerStatefulWidget {
  const CollectDialog({super.key});

  @override
  ConsumerState<CollectDialog> createState() => _CollectDialogState();
}

class _CollectDialogState extends ConsumerState<CollectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(inboxRepositoryProvider).add(rawText: text, source: TaskSource.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: GlassContainer(
        color: scheme.surface, // app 主题下 = tokens.card
        blur: 12,
        saturate: 1.8,
        borderColor: scheme.outline, // app 主题下 = tokens.stroke
        borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.collectAction,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('collect_dialog_field'),
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.quickCollectHint),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                GradientButton(
                  key: const Key('collect_dialog_submit'),
                  onPressed: _submit,
                  minimumSize: const Size(72, 40),
                  child: Text(l10n.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
