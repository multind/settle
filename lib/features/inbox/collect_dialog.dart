import 'package:flutter/material.dart';
import 'package:gtd_app/app/glass.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';

/// 全局快速收集对话框（shell FAB 复用，任意界面 1 步发起收集，规格 §7.3）。
///
/// 视觉：`Dialog` 透明底 + `GlassContainer`（blur σ12 / saturate 1.8 / stroke 描边 /
/// 彩色阴影，圆角 18），提交按钮为 `GradientButton`（accent2→accent 渐变 + 光晕）。
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
        shadow: const [
          BoxShadow(
            color: Color(0x472456FF), // rgba(36,86,255,.28)
            blurRadius: 50,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x1F141B33), // rgba(20,27,51,.12)
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
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
