import 'package:flutter/material.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/data/providers.dart';

/// 收件箱顶部常驻快速收集框（规格 §7.1：只要求"写一句话"）。
///
/// 视觉（preview `.quickbar`）：accent2→accent 渐变底 + 白色提示文字 +
/// 白色半透明圆钮（M1 无语音按钮，圆钮即"+"提交）+ 绿色光晕 + 高光描边 + 圆角 16。
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
    final ext = Theme.of(context).extension<ColorSchemeExtension>();
    // accent 不在 extension 中，取 ColorScheme.secondary（app 主题下 = tokens.accent）。
    final accent2 = ext?.accent2 ?? const Color(0xFF00B478);
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent2, accent],
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: const Color(0x59FFFFFF)), // rgba(255,255,255,.35)
          boxShadow: const [
            BoxShadow(
              color: Color(0x7300B478), // rgba(0,180,120,.45)
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('quick_collect_field'),
                  controller: _controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: l10n.quickCollectHint,
                    hintStyle: const TextStyle(
                      color: Color(0xB3FFFFFF), // 白色 70%
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _collect(),
                ),
              ),
              const SizedBox(width: 8),
              // 白色半透明圆钮（preview `.mic`，M1 无语音按钮，圆钮即"+"提交）
              IconButton(
                key: const Key('quick_collect_button'),
                onPressed: _collect,
                tooltip: l10n.collectAction,
                icon: const Icon(Icons.add, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x4DFFFFFF), // rgba(255,255,255,.3)
                  foregroundColor: Colors.white,
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  side: const BorderSide(color: Color(0x66FFFFFF)), // inset 高光
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
