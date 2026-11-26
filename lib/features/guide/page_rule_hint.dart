import 'package:flutter/material.dart';
import 'package:settle_app/app/theme.dart';

/// 页级空态规则提示（GTD 使用指南单元一）：图标 + 纪律标题 + 纪律正文。
/// 各页把既有 `Center(child: Text(l10n.xxxEmpty))` 等位替换为
/// `Center(child: PageRuleHint(icon: …, title: …, message: …))`
/// （结构不变、布局风险最低）。文案由页面以 l10n 已解析字符串传入。
class PageRuleHint extends StatelessWidget {
  const PageRuleHint({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  /// 页面图标（复用导航图标，与侧边栏视觉一致）。
  final IconData icon;

  /// 纪律标题（l10n 已解析字符串，页面传入）。
  final String title;

  /// 纪律正文（l10n 已解析字符串，页面传入）。
  final String message;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return ConstrainedBox(
      key: const Key('page_rule_hint'),
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: tokens.muted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: tokens.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: tokens.muted),
          ),
        ],
      ),
    );
  }
}
