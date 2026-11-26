import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';

/// GTD 指南页（导航 index 11，GTD 使用指南单元三）：四分区——
/// ① 三条铁律 / ② 每天固定动作 / ③ 各清单使用规则（6 小卡）/ ④ 注意事项。
/// 文案全部走 l10n：①/② 与引导卡共用铁律/每日动作 key；③ 复用各页空态
/// `rule*Title/Message` 并各附一句示例；④ 四条注意事项。
/// 视觉 Things 3 极简：GlassContainer 纯底 + 1px hairline + 圆角 8，零阴影。
class GtdGuidePage extends StatelessWidget {
  const GtdGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navGuide)),
      body: ListView(
        key: const Key('guide_list'),
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _sectionTitle(tokens, l10n.guideSectionLaws),
          _textCard(
            tokens,
            lines: [
              _textLine(tokens, l10n.ironRule1),
              _textLine(tokens, l10n.ironRule2),
              _textLine(tokens, l10n.ironRule3),
            ],
          ),
          _sectionTitle(tokens, l10n.guideSectionDaily),
          _textCard(
            tokens,
            lines: [
              _textLine(tokens, l10n.dailyAction1),
              _textLine(tokens, l10n.dailyAction2),
              _textLine(tokens, l10n.dailyAction3),
            ],
          ),
          _sectionTitle(tokens, l10n.guideSectionLists),
          _ruleCard(tokens, Icons.inbox_outlined, l10n.ruleInboxTitle,
              l10n.ruleInboxMessage, l10n.guideExampleInbox),
          _ruleCard(tokens, Icons.today, l10n.ruleTodayTitle,
              l10n.ruleTodayMessage, l10n.guideExampleToday),
          _ruleCard(tokens, Icons.hourglass_empty, l10n.ruleWaitingTitle,
              l10n.ruleWaitingMessage, l10n.guideExampleWaiting),
          _ruleCard(tokens, Icons.folder_outlined, l10n.ruleProjectsTitle,
              l10n.ruleProjectsMessage, l10n.guideExampleProject),
          _ruleCard(tokens, Icons.nights_stay_outlined, l10n.ruleSomedayTitle,
              l10n.ruleSomedayMessage, l10n.guideExampleSomeday),
          _ruleCard(tokens, Icons.event_outlined, l10n.ruleUpcomingTitle,
              l10n.ruleUpcomingMessage, l10n.guideExampleUpcoming),
          _sectionTitle(tokens, l10n.guideSectionNotes),
          _textCard(
            tokens,
            lines: [
              _textLine(tokens, l10n.guideNote1),
              _textLine(tokens, l10n.guideNote2),
              _textLine(tokens, l10n.guideNote3),
              _textLine(tokens, l10n.guideNote4),
            ],
          ),
        ],
      ),
    );
  }

  /// 分区组标题（muted 12 w600，与外壳侧边栏 _groupTitle 同款样式）。
  Widget _sectionTitle(AppTokenSet tokens, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
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
  Widget _textLine(AppTokenSet tokens, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: TextStyle(fontSize: 13, color: tokens.text)),
    );
  }

  /// 文本分区卡片（①/②/④）：GlassContainer 纯底 + hairline + 圆角 8。
  Widget _textCard(AppTokenSet tokens, {required List<Widget> lines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        color: tokens.cardSolid,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      ),
    );
  }

  /// 清单规则小卡（③）：图标 + 标题 + 正文 + 一句示例。
  Widget _ruleCard(AppTokenSet tokens, IconData icon, String title,
      String message, String example) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: GlassContainer(
        color: tokens.cardSolid,
        borderColor: tokens.stroke,
        borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: tokens.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(fontSize: 12, color: tokens.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    example,
                    style: TextStyle(fontSize: 12, color: tokens.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
