import 'package:flutter/material.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';

/// 收件箱顶部常驻快速收集框（规格 §7.1：只要求"写一句话"）。
///
/// 视觉（Things 3 输入框）：`field` 纯底填充 + `stroke` 细描边 + 圆角 8，
/// 文字/hint 用 `text`/`muted`（不再白色），提交钮为实色 primary 圆形"+"按钮。
class QuickCollectBar extends ConsumerStatefulWidget {
  const QuickCollectBar({super.key});

  @override
  ConsumerState<QuickCollectBar> createState() => _QuickCollectBarState();
}

class _QuickCollectBarState extends ConsumerState<QuickCollectBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await ref.read(inboxRepositoryProvider).add(rawText: text, source: TaskSource.text);
    _controller.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.collectAction)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.field,
          borderRadius: BorderRadius.circular(AppTokens.radiusField),
          border: Border.all(color: tokens.stroke),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('quick_collect_field'),
                  controller: _controller,
                  style: TextStyle(
                    color: tokens.text,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: tokens.primary,
                  decoration: InputDecoration(
                    hintText: l10n.quickCollectHint,
                    hintStyle: TextStyle(color: tokens.muted),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _collect(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                key: const Key('quick_collect_button'),
                onPressed: _collect,
                tooltip: l10n.collectAction,
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: tokens.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
