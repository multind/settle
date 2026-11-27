import 'package:settle_app/i18n/l10n/app_localizations.dart';

/// 16 动作 labelKey → l10n 文本集中解析（与壳层 `_labelOf` 同款 switch 模式）：
/// 配置页行 title 与录键弹窗冲突文案共用，避免两处各写一份。
String actionLabel(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    case 'actionCollect':
      return l10n.actionCollect;
    case 'actionNavInbox':
      return l10n.actionNavInbox;
    case 'actionNavToday':
      return l10n.actionNavToday;
    case 'actionNavUpcoming':
      return l10n.actionNavUpcoming;
    case 'actionNavAnytime':
      return l10n.actionNavAnytime;
    case 'actionNavSomeday':
      return l10n.actionNavSomeday;
    case 'actionNavProjects':
      return l10n.actionNavProjects;
    case 'actionNavContexts':
      return l10n.actionNavContexts;
    case 'actionNavWaiting':
      return l10n.actionNavWaiting;
    case 'actionNavLogbook':
      return l10n.actionNavLogbook;
    case 'actionNavReview':
      return l10n.actionNavReview;
    case 'actionListUp':
      return l10n.actionListUp;
    case 'actionListDown':
      return l10n.actionListDown;
    case 'actionListComplete':
      return l10n.actionListComplete;
    case 'actionListDelete':
      return l10n.actionListDelete;
    case 'actionToggleAlwaysOnTop':
      return l10n.actionToggleAlwaysOnTop;
    default:
      throw ArgumentError('未知快捷键动作 labelKey: $labelKey');
  }
}
