import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';

/// 首次引导卡（GTD 使用指南单元二）：首启外壳内容列顶部 in-flow 横幅——
/// 标题 + × 关闭 + 三条铁律 + 每天固定动作 + 底部 CTA（查看完整指南）。
/// 关闭与 CTA 均经回调由外壳置位 `gtd_guide_seen` 并（CTA）切到指南页 index 11。
/// 视觉 Things 3 极简：GlassContainer（cardSolid + stroke hairline + 圆角 8，零阴影）。
class OnboardingCard extends StatelessWidget {
  const OnboardingCard({
    super.key,
    required this.onDismiss,
    required this.onOpenGuide,
  });

  /// 右上角 ×：隐藏卡片并置位已看过。
  final VoidCallback onDismiss;

  /// 「查看完整指南 →」CTA：置位已看过 + 切到指南页。
  final VoidCallback onOpenGuide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return GlassContainer(
      key: const Key('onboarding_card'),
      color: tokens.cardSolid,
      borderColor: tokens.stroke,
      borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.onboardingTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tokens.text,
                  ),
                ),
              ),
              IconButton(
                key: const Key('onboarding_close'),
                tooltip: l10n.onboardingClose,
                icon: const Icon(Icons.close, size: 18),
                color: tokens.muted,
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          _sectionTitle(tokens, l10n.guideSectionLaws),
          _line(tokens, l10n.ironRule1),
          _line(tokens, l10n.ironRule2),
          _line(tokens, l10n.ironRule3),
          const SizedBox(height: 8),
          _sectionTitle(tokens, l10n.guideSectionDaily),
          _line(tokens, l10n.dailyAction1),
          _line(tokens, l10n.dailyAction2),
          _line(tokens, l10n.dailyAction3),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('onboarding_open_guide'),
              onPressed: onOpenGuide,
              child: Text(l10n.onboardingOpenGuide),
            ),
          ),
        ],
      ),
    );
  }

  /// 小节标题（muted 12 w600）。
  Widget _sectionTitle(AppTokenSet tokens, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.muted,
        ),
      ),
    );
  }

  /// 单行文案（13px 正文）。
  Widget _line(AppTokenSet tokens, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: TextStyle(fontSize: 13, color: tokens.text)),
    );
  }
}
