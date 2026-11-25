import 'package:flutter/material.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/features/anytime/anytime_page.dart';
import 'package:gtd_app/features/contexts/contexts_page.dart';
import 'package:gtd_app/features/inbox/collect_dialog.dart';
import 'package:gtd_app/features/inbox/inbox_page.dart';
import 'package:gtd_app/features/logbook/logbook_page.dart';
import 'package:gtd_app/features/projects/projects_page.dart';
import 'package:gtd_app/features/review/review_page.dart';
import 'package:gtd_app/features/settings/settings_page.dart';
import 'package:gtd_app/features/someday/someday_page.dart';
import 'package:gtd_app/features/today/today_page.dart';
import 'package:gtd_app/features/upcoming/upcoming_page.dart';
import 'package:gtd_app/features/waiting/waiting_page.dart';

/// 响应式外壳（规格 §2）：LayoutBuilder 600px 断点。
/// 宽屏：自定义可滚动分组侧边栏（11 项三组：时间/组织/系统，替换 NavigationRail）；
/// 窄屏：底部 NavigationBar 5 项（收件箱/今日/即将/随时/更多）+「更多」抽屉。
class ResponsiveShell extends ConsumerStatefulWidget {
  const ResponsiveShell({super.key});

  static const double breakpoint = 600;

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _index = 0;

  /// 底部栏当前高亮位（0..4）：仅直接点按的 4 项更新；
  /// 经「更多」抽屉切页时保持原高亮（NavigationBar 不允许 selectedIndex < 0）。
  int _narrowIndex = 0;

  /// 全局视图索引表（规格 §2.1）：唯一事实源，
  /// 侧边栏 / 底部 / 「更多」抽屉三处渲染共用此顺序。
  static const List<Widget> _pages = [
    InboxPage(), // 0 收件箱
    TodayPage(), // 1 今日
    UpcomingPage(), // 2 即将（占位，Task 4 填充）
    AnytimePage(), // 3 随时（占位，Task 3 填充）
    SomedayPage(), // 4 将来也许
    ProjectsPage(), // 5 项目
    ContextsPage(), // 6 情境
    WaitingPage(), // 7 等待
    LogbookPage(), // 8 日志（占位，Task 5 填充）
    ReviewPage(), // 9 回顾
    SettingsPage(), // 10 设置
  ];

  /// 窄屏底部 5 项对应 _pages 下标：收件箱/今日/即将/随时 + 「更多」（弹抽屉）。
  static const List<int> _narrowIndices = [0, 1, 2, 3];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= ResponsiveShell.breakpoint;
        return Scaffold(
          body: isWide
              ? Row(
                  children: [
                    _buildSidebar(context, l10n, tokens),
                    Expanded(child: _pages[_index]),
                  ],
                )
              : _pages[_index],
          bottomNavigationBar: isWide
              ? null
              : Container(
                  decoration: BoxDecoration(
                    color: tokens.nav,
                    border: Border(
                      top: BorderSide(color: tokens.stroke, width: 1),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _narrowIndex,
                    onDestinationSelected: (i) =>
                        _onNarrowSelected(context, l10n, i),
                    destinations: _barDestinations(l10n),
                  ),
                ),
          floatingActionButton: !const {0, 5, 6, 9}.contains(_index)
              ? FloatingActionButton(
                  key: const Key('global_collect_fab'),
                  tooltip: l10n.collectAction,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const CollectDialog(),
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  /// 宽屏分组侧边栏（规格 §2.2）：纯底 + 右侧 1px hairline，可滚动（ListView）。
  Widget _buildSidebar(
      BuildContext context, AppLocalizations l10n, AppTokenSet tokens) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: tokens.sidebar,
        border: Border(
          right: BorderSide(color: tokens.stroke, width: 1),
        ),
      ),
      child: ListView(
        key: const Key('custom_sidebar'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _BrandMark(),
          _navItem(tokens, 0, Icons.inbox_outlined, l10n.navInbox),
          _groupTitle(tokens, const Key('nav_group_time'), l10n.navGroupTime),
          _navItem(tokens, 1, Icons.today, l10n.navToday),
          _navItem(tokens, 2, Icons.event_outlined, l10n.navUpcoming),
          _navItem(tokens, 3, Icons.all_inclusive_outlined, l10n.navAnytime),
          _navItem(tokens, 4, Icons.nights_stay_outlined, l10n.navSomeday),
          _groupTitle(
              tokens, const Key('nav_group_organize'), l10n.navGroupOrganize),
          _navItem(tokens, 5, Icons.folder_outlined, l10n.navProjects),
          _navItem(tokens, 6, Icons.place_outlined, l10n.navContexts),
          _navItem(tokens, 7, Icons.hourglass_empty, l10n.navWaiting),
          _groupTitle(
              tokens, const Key('nav_group_system'), l10n.navGroupSystem),
          _navItem(tokens, 8, Icons.book_outlined, l10n.navLogbook),
          _navItem(tokens, 9, Icons.history, l10n.navReview),
          _navItem(tokens, 10, Icons.settings_outlined, l10n.navSettings),
        ],
      ),
    );
  }

  /// 侧边栏单项（规格 §2.2）：InkWell 切换 `_index`；
  /// 选中态复用 v0.2 语义（selectedBg 圆角底 + primary 图标/文字）。
  Widget _navItem(AppTokenSet tokens, int index, IconData icon, String label) {
    final selected = _index == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        key: Key('nav_item_$index'),
        onTap: () => setState(() => _index = index),
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? tokens.selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? tokens.primary : tokens.muted,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? tokens.primary : tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 侧边栏组标题（规格 §2.2）：muted 12px 小字。
  Widget _groupTitle(AppTokenSet tokens, Key key, String title) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
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

  /// 窄屏底部项选中（规格 §2.3）：前 4 项直接切页；最后「更多」弹抽屉。
  void _onNarrowSelected(BuildContext context, AppLocalizations l10n, int i) {
    if (i >= _narrowIndices.length) {
      _showMoreSheet(context, l10n);
    } else {
      setState(() {
        _narrowIndex = i;
        _index = _narrowIndices[i];
      });
    }
  }

  /// 「更多」抽屉（规格 §2.3）：项目/情境/等待/日志/回顾/设置，点选切页并关 sheet。
  void _showMoreSheet(BuildContext context, AppLocalizations l10n) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: tokens.cardSolid,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusContainer)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, icon, label) in _moreItems(l10n))
              ListTile(
                key: Key('nav_more_item_$index'),
                leading: Icon(icon, size: 20),
                title: Text(label),
                onTap: () {
                  setState(() => _index = index);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  List<(int, IconData, String)> _moreItems(AppLocalizations l10n) => [
        (5, Icons.folder_outlined, l10n.navProjects),
        (6, Icons.place_outlined, l10n.navContexts),
        (7, Icons.hourglass_empty, l10n.navWaiting),
        (8, Icons.book_outlined, l10n.navLogbook),
        (9, Icons.history, l10n.navReview),
        (10, Icons.settings_outlined, l10n.navSettings),
      ];

  List<NavigationDestination> _barDestinations(AppLocalizations l10n) => [
        NavigationDestination(
          icon: const Icon(Icons.inbox_outlined),
          selectedIcon: const Icon(Icons.inbox),
          label: l10n.navInbox,
        ),
        NavigationDestination(
          icon: const Icon(Icons.today),
          selectedIcon: const Icon(Icons.today),
          label: l10n.navToday,
        ),
        NavigationDestination(
          icon: const Icon(Icons.event_outlined),
          selectedIcon: const Icon(Icons.event),
          label: l10n.navUpcoming,
        ),
        NavigationDestination(
          icon: const Icon(Icons.all_inclusive_outlined),
          selectedIcon: const Icon(Icons.all_inclusive),
          label: l10n.navAnytime,
        ),
        NavigationDestination(
          icon: const Icon(Icons.more_horiz),
          selectedIcon: const Icon(Icons.more_horiz),
          label: l10n.navMore,
        ),
      ];
}

/// 品牌字「GTD」（preview `.brand`）：普通 `text` 粗体文字，无渐变。
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
      child: Text(
        'GTD',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: tokens.text,
        ),
      ),
    );
  }
}
