import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';
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
import 'package:gtd_app/features/task/reminder_service.dart';
import 'package:gtd_app/features/task/task_edit_dialog.dart';
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

  /// 底部栏「更多」槽位（最后一个目的地，弹抽屉而非切页）。
  static const int _kMoreIndex = 4;

  /// 应用内到点提醒服务（v0.3 调度 §4.2）：initState 启动、dispose 取消。
  ReminderService? _reminderService;
  StreamSubscription<List<Task>>? _reminderSub;

  @override
  void initState() {
    super.initState();
    final service = ReminderService(ref.read(taskRepositoryProvider));
    _reminderService = service;
    service.start();
    _reminderSub = service.reminders.listen(_onReminders);
  }

  @override
  void dispose() {
    _reminderSub?.cancel();
    _reminderService?.dispose();
    super.dispose();
  }

  /// 提醒流命中（规格 §4.2）：逐条排队弹顶部 MaterialBanner
  /// （ScaffoldMessenger 的 banner 队列天然串行展示）。
  void _onReminders(List<Task> tasks) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    for (final task in tasks) {
      messenger.showMaterialBanner(
        MaterialBanner(
          key: Key('reminder_banner_${task.id}'),
          leading: const Icon(Icons.alarm),
          content: Text(l10n.reminderBannerTitle(task.title)),
          actions: [
            TextButton(
              key: Key('reminder_open_${task.id}'),
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                _openTask(task);
              },
              child: Text(l10n.reminderOpen),
            ),
            TextButton(
              key: Key('reminder_dismiss_${task.id}'),
              onPressed: messenger.hideCurrentMaterialBanner,
              child: Text(l10n.reminderDismiss),
            ),
          ],
        ),
      );
    }
  }

  /// [打开]：隐藏当前 Banner 后弹该任务编辑对话框。
  void _openTask(Task task) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => TaskEditDialog(task: task),
    );
  }

  /// 全局视图索引表（规格 §2.1）：index i ↔ [_navSpecs][i] ↔ `_pages[i]`，
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
                    _buildSidebar(l10n, tokens),
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
          // FAB 显隐由规范表派生：仅 collectFab 页显示全局收集 FAB
          // （等价于语义 !{0,5,6,9}：收件箱/项目/情境/回顾 隐藏）。
          floatingActionButton: _navSpecs[_index].collectFab
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
  /// 结构完全由 [_navSpecs] 派生：收件箱置顶无组标题，其后按组归属插入组标题。
  Widget _buildSidebar(AppLocalizations l10n, AppTokenSet tokens) {
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
          for (var i = 0; i < _navSpecs.length; i++) ...[
            // 组首项：在组标题前插入（收件箱 group 为空，天然跳过）。
            if (_navSpecs[i].group != null &&
                (i == 0 || _navSpecs[i - 1].group != _navSpecs[i].group))
              _groupTitle(
                tokens,
                Key('nav_group_${_navSpecs[i].group!.name}'),
                _labelOf(l10n, _navSpecs[i].group!.labelKey),
              ),
            _navItem(tokens, _navSpecs[i], _labelOf(l10n, _navSpecs[i].labelKey)),
          ],
        ],
      ),
    );
  }

  /// 侧边栏单项（规格 §2.2）：InkWell 切换 `_index`；
  /// 选中态复用 v0.2 语义（selectedBg 圆角底 + primary 图标/文字）。
  Widget _navItem(AppTokenSet tokens, _NavSpec spec, String label) {
    final selected = _index == spec.index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        key: Key('nav_item_${spec.index}'),
        onTap: () => setState(() => _index = spec.index),
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
                spec.icon,
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

  /// 侧边栏组标题（规格 §2.2）：muted 12px 小字；左缘与导航项图标列（8+10=18）对齐。
  Widget _groupTitle(AppTokenSet tokens, Key key, String title) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 4),
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
    if (i == _kMoreIndex) {
      _showMoreSheet(context, l10n);
    } else {
      setState(() {
        _narrowIndex = i;
        _index = _navSpecs[i].index;
      });
    }
  }

  /// 「更多」抽屉（规格 §2.3）：由 [_navSpecs] 派生 inMore 项，
  /// 点选切页并关 sheet。
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
            for (final spec in _navSpecs.where((s) => s.inMore))
              ListTile(
                key: Key('nav_more_item_${spec.index}'),
                leading: Icon(spec.icon, size: 20),
                title: Text(_labelOf(l10n, spec.labelKey)),
                onTap: () {
                  setState(() => _index = spec.index);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 底部栏目的地（规格 §2.3）：inNarrow 4 页 + 「更多」槽位，均由规范表派生。
  List<NavigationDestination> _barDestinations(AppLocalizations l10n) => [
        for (final spec in _navSpecs.where((s) => s.inNarrow))
          NavigationDestination(
            icon: Icon(spec.icon),
            selectedIcon: Icon(spec.selectedIcon),
            label: _labelOf(l10n, spec.labelKey),
          ),
        NavigationDestination(
          icon: const Icon(Icons.more_horiz),
          selectedIcon: const Icon(Icons.more_horiz),
          label: _labelOf(l10n, 'navMore'),
        ),
      ];
}

/// 侧边栏组归属（规格 §2.2）。name 直接派生组标题 Key（nav_group_$name）。
enum _NavGroup {
  time('navGroupTime'),
  organize('navGroupOrganize'),
  system('navGroupSystem');

  const _NavGroup(this.labelKey);

  /// 组标题的 l10n key（app_zh.arb/app_en.arb）。
  final String labelKey;
}

/// 单个导航目的地规范：全局索引 / 图标 / selectedIcon / l10n key / FAB 显隐 /
/// 侧边栏组归属 / 底部栏与抽屉归属。全部字段 const，渲染时经 [_labelOf] 查找文本。
class _NavSpec {
  const _NavSpec({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
    required this.collectFab,
    this.group,
    this.inNarrow = false,
    this.inMore = false,
  });

  /// 全局视图索引（0..10，对应 [_ResponsiveShellState._pages]）。
  final int index;
  final IconData icon;
  final IconData selectedIcon;

  /// l10n key 字符串（非文本），保持规范表 const。
  final String labelKey;

  /// 该页是否显示全局收集 FAB（语义 !{0,5,6,9}）。
  final bool collectFab;

  /// 侧边栏组归属；null = 无组（收件箱置顶）。
  final _NavGroup? group;

  /// 是否直接出现在窄屏底部栏（收件箱/今日/即将/随时）。
  final bool inNarrow;

  /// 是否出现在「更多」抽屉（项目/情境/等待/日志/回顾/设置）。
  final bool inMore;
}

/// 导航目的地规范表（唯一事实源）：侧边栏 11 项 / 底部栏 / 更多抽屉 / FAB 显隐
/// 全部由此派生。底部 4 项 + 抽屉 6 项 + 侧边栏专属（将来也许）覆盖全部 11 页。
const List<_NavSpec> _navSpecs = [
  _NavSpec(
    index: 0,
    icon: Icons.inbox_outlined,
    selectedIcon: Icons.inbox,
    labelKey: 'navInbox',
    collectFab: false,
    inNarrow: true,
  ),
  _NavSpec(
    index: 1,
    icon: Icons.today,
    selectedIcon: Icons.today,
    labelKey: 'navToday',
    collectFab: true,
    group: _NavGroup.time,
    inNarrow: true,
  ),
  _NavSpec(
    index: 2,
    icon: Icons.event_outlined,
    selectedIcon: Icons.event,
    labelKey: 'navUpcoming',
    collectFab: true,
    group: _NavGroup.time,
    inNarrow: true,
  ),
  _NavSpec(
    index: 3,
    icon: Icons.all_inclusive_outlined,
    selectedIcon: Icons.all_inclusive,
    labelKey: 'navAnytime',
    collectFab: true,
    group: _NavGroup.time,
    inNarrow: true,
  ),
  _NavSpec(
    index: 4,
    icon: Icons.nights_stay_outlined,
    selectedIcon: Icons.nights_stay_outlined,
    labelKey: 'navSomeday',
    collectFab: true,
    group: _NavGroup.time,
  ),
  _NavSpec(
    index: 5,
    icon: Icons.folder_outlined,
    selectedIcon: Icons.folder,
    labelKey: 'navProjects',
    collectFab: false,
    group: _NavGroup.organize,
    inMore: true,
  ),
  _NavSpec(
    index: 6,
    icon: Icons.place_outlined,
    selectedIcon: Icons.place,
    labelKey: 'navContexts',
    collectFab: false,
    group: _NavGroup.organize,
    inMore: true,
  ),
  _NavSpec(
    index: 7,
    icon: Icons.hourglass_empty,
    selectedIcon: Icons.hourglass_empty,
    labelKey: 'navWaiting',
    collectFab: true,
    group: _NavGroup.organize,
    inMore: true,
  ),
  _NavSpec(
    index: 8,
    icon: Icons.book_outlined,
    selectedIcon: Icons.book,
    labelKey: 'navLogbook',
    collectFab: true,
    group: _NavGroup.system,
    inMore: true,
  ),
  _NavSpec(
    index: 9,
    icon: Icons.history,
    selectedIcon: Icons.history,
    labelKey: 'navReview',
    collectFab: false,
    group: _NavGroup.system,
    inMore: true,
  ),
  _NavSpec(
    index: 10,
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    labelKey: 'navSettings',
    collectFab: true,
    group: _NavGroup.system,
    inMore: true,
  ),
];

/// 由 l10n key 解析本地化文本（AppLocalizations 无 byKey 查找，集中此一处）。
String _labelOf(AppLocalizations l10n, String key) {
  switch (key) {
    case 'navInbox':
      return l10n.navInbox;
    case 'navToday':
      return l10n.navToday;
    case 'navUpcoming':
      return l10n.navUpcoming;
    case 'navAnytime':
      return l10n.navAnytime;
    case 'navSomeday':
      return l10n.navSomeday;
    case 'navProjects':
      return l10n.navProjects;
    case 'navContexts':
      return l10n.navContexts;
    case 'navWaiting':
      return l10n.navWaiting;
    case 'navLogbook':
      return l10n.navLogbook;
    case 'navReview':
      return l10n.navReview;
    case 'navSettings':
      return l10n.navSettings;
    case 'navMore':
      return l10n.navMore;
    case 'navGroupTime':
      return l10n.navGroupTime;
    case 'navGroupOrganize':
      return l10n.navGroupOrganize;
    case 'navGroupSystem':
      return l10n.navGroupSystem;
    default:
      throw ArgumentError('未知导航 l10n key: $key');
  }
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
