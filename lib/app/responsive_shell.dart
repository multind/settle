import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/features/anytime/anytime_page.dart';
import 'package:settle_app/features/contexts/contexts_page.dart';
import 'package:settle_app/features/guide/gtd_guide_page.dart';
import 'package:settle_app/features/guide/onboarding_card.dart';
import 'package:settle_app/features/inbox/collect_dialog.dart';
import 'package:settle_app/features/inbox/inbox_page.dart';
import 'package:settle_app/features/logbook/logbook_page.dart';
import 'package:settle_app/features/projects/projects_page.dart';
import 'package:settle_app/features/review/review_page.dart';
import 'package:settle_app/features/settings/settings_page.dart';
import 'package:settle_app/features/someday/someday_page.dart';
import 'package:settle_app/features/task/reminder_service.dart';
import 'package:settle_app/features/task/task_edit_dialog.dart';
import 'package:settle_app/features/today/today_page.dart';
import 'package:settle_app/features/upcoming/upcoming_page.dart';
import 'package:settle_app/features/waiting/waiting_page.dart';

/// 响应式外壳（规格 §2）：LayoutBuilder 600px 断点。
/// 宽屏：自定义可滚动分组侧边栏（12 项三组：时间/组织/系统，替换 NavigationRail）；
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

  /// 首启引导卡显隐（GTD 指南单元二）：initState 同步读 prefs `gtd_guide_seen`
  /// 初始化（缺省未看过 → 展示）。
  bool _showGuideCard = false;

  @override
  void initState() {
    super.initState();
    _showGuideCard =
        !(ref.read(sharedPreferencesProvider).getBool('gtd_guide_seen') ?? false);
    _pages = [
      const InboxPage(), // 0 收件箱
      const TodayPage(), // 1 今日
      const UpcomingPage(), // 2 即将
      const AnytimePage(), // 3 随时
      const SomedayPage(), // 4 将来也许
      const ProjectsPage(), // 5 项目
      const ContextsPage(), // 6 情境
      const WaitingPage(), // 7 等待
      const LogbookPage(), // 8 日志
      const ReviewPage(), // 9 回顾
      SettingsPage(onOpenGuide: () => _switchTo(11)), // 10 设置（闭包非 const）
      const GtdGuidePage(), // 11 GTD 指南
    ];
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
  /// 非 const：SettingsPage 需外壳注入回调（onOpenGuide → _switchTo(11)）。
  late final List<Widget> _pages;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    final Widget shell = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= ResponsiveShell.breakpoint;
        return Scaffold(
          body: isWide
              ? Row(
                  children: [
                    _buildSidebar(l10n, tokens),
                    Expanded(child: _pageColumn()),
                  ],
                )
              : _pageColumn(),
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
    // 桌面平台全局快捷键（规格 §5）：N → 收集；Ctrl/Cmd+1..9 → 侧边栏第
    // 1..9 项（收件箱..日志）；Ctrl/Cmd+0 → 回顾。仅桌面（含 Web）包裹
    // Shortcuts/Actions；文本输入焦点时经 [isEnabled] 门控放行按键。
    if (!_shortcutsEnabled) return shell;
    final Map<ShortcutActivator, Intent> shortcuts = {
      const SingleActivator(LogicalKeyboardKey.keyN): const _CollectIntent(),
      // Ctrl/Cmd+0 → 回顾：索引由规范表派生（_digitKeys 9 项之后的首项，
      // 即 _navSpecs[9] = 回顾），与下方 1..9 派生循环共用同一事实源。
      const SingleActivator(LogicalKeyboardKey.digit0, control: true):
          _SwitchViewIntent(_navSpecs[_digitKeys.length].index),
      const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
          _SwitchViewIntent(_navSpecs[_digitKeys.length].index),
    };
    // Ctrl/Cmd+n → 侧边栏第 n 项（_navSpecs 项序即全局索引序，n-1 = 索引）。
    for (var n = 0; n < _digitKeys.length; n++) {
      final index = _navSpecs[n].index;
      shortcuts[SingleActivator(_digitKeys[n], control: true)] =
          _SwitchViewIntent(index);
      shortcuts[SingleActivator(_digitKeys[n], meta: true)] =
          _SwitchViewIntent(index);
    }
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          _CollectIntent: _ShellAction<_CollectIntent>(
            enabled: () => !_isTextEditingFocus(),
            onInvoke: (_) {
              if (!mounted) return null;
              showDialog<void>(
                context: context,
                builder: (_) => const CollectDialog(),
              );
              return true;
            },
          ),
          _SwitchViewIntent: _ShellAction<_SwitchViewIntent>(
            enabled: () => !_isTextEditingFocus(),
            onInvoke: (intent) {
              if (!mounted) return null;
              _switchTo(intent.index);
              return true;
            },
          ),
        },
        // 启动默认焦点（M-6 修复）：Shortcuts 按键事件自
        // FocusManager.instance.primaryFocus 所在节点沿祖先链冒泡查找；
        // ShortcutManager.handleKeypress 也以 primaryFocus.context 定位
        // Actions。应用启动后未点击/未 Tab 时 primaryFocus 为 null，按键
        // 不进入本子树 → 快捷键全部失效。此 Focus(autofocus: true) 在首帧
        // 取得主焦点（位于 Shortcuts/Actions 子树内），启动即按 N /
        // Ctrl+数字即可冒泡触发。skipTraversal 使该不可见锚点不成为 Tab
        // 停靠点，Tab 遍历仍直达真实控件（不改变既有键盘遍历行为）。
        //
        // 空白点击评估（M-6）：Flutter 点击不可聚焦区域（Container/Text
        // 空白处）不会清除 primary focus（widget 测试实证），无需额外
        // 恢复焦点逻辑。已知残余限制：焦点所在控件被销毁时（如快捷键切页
        // 移除带焦点的控件）primary focus 可能回 null，autofocus 不重复
        // 触发，需再次点击/Tab 恢复——超出本次启动焦点修复范围。
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: shell,
        ),
      ),
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

  /// 桌面平台判定（规格 §5）：快捷键仅桌面（含 Web）启用。
  /// 平台能力判定已收敛至 PlatformBridge（同一 defaultTargetPlatform + kIsWeb
  /// 事实源，行为零变化）；getter 保留调用点命名语义。
  bool get _shortcutsEnabled {
    final PlatformBridge bridge = ref.read(platformBridgeProvider);
    return bridge.supportsKeyboardShortcuts;
  }

  /// 文本输入焦点判定：primary focus 落在 `EditableText`（TextField 底层）
  /// 上时不触发全局快捷键，让 N/数字键正常输入（规格 §5 不拦截约束）。
  /// 经 [Shortcuts] 的 isEnabled 门控实现：返回 false 时事件继续冒泡到输入框。
  bool _isTextEditingFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        context.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// 快捷键切视图：同步 `_index` 与窄屏底部栏高亮位（目标为 inNarrow 项时
  /// 更新 _narrowIndex，镜像 [_onNarrowSelected] 语义）。
  void _switchTo(int index) {
    setState(() {
      _index = index;
      final pos = _navSpecs.indexWhere((s) => s.inNarrow && s.index == index);
      if (pos != -1) _narrowIndex = pos;
    });
  }

  /// 关闭引导卡（右上角 ×）：隐藏卡片并持久化已看过（fire-and-forget）。
  void _dismissGuideCard() {
    setState(() => _showGuideCard = false);
    unawaited(
        ref.read(sharedPreferencesProvider).setBool('gtd_guide_seen', true));
  }

  /// 打开完整指南：视为已看过（置位 + 隐藏卡片）并切到指南页 index 11。
  /// 决策点：CTA 视为「已看过」——用户已主动进入完整指南，卡片不再滞留。
  void _openGuide() {
    setState(() => _showGuideCard = false);
    unawaited(
        ref.read(sharedPreferencesProvider).setBool('gtd_guide_seen', true));
    _switchTo(11);
  }

  /// 内容列：引导卡显示时以 in-flow 布局置于页面之上（页面 AppBar 之上、
  /// 全局 FAB 与底部导航之外），从结构上杜绝遮挡任何 FAB/导航元素。
  Widget _pageColumn() {
    if (!_showGuideCard) return _pages[_index];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: OnboardingCard(
            onDismiss: _dismissGuideCard,
            onOpenGuide: _openGuide,
          ),
        ),
        Expanded(child: _pages[_index]),
      ],
    );
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

  /// 全局视图索引（0..11，对应 [_ResponsiveShellState._pages]）。
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

  /// 是否出现在「更多」抽屉（项目/情境/等待/日志/回顾/设置/GTD 指南）。
  final bool inMore;
}

/// 导航目的地规范表（唯一事实源）：侧边栏 12 项 / 底部栏 / 更多抽屉 / FAB 显隐
/// 全部由此派生。底部 4 项 + 抽屉 7 项 + 侧边栏专属（将来也许）覆盖全部 12 页。
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
  _NavSpec(
    index: 11,
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_outlined,
    labelKey: 'navGuide',
    collectFab: false,
    group: _NavGroup.system,
    inMore: true,
  ),
];

/// 快捷键数字键表（Ctrl/Cmd+1..9，按侧边栏项序；下标 n ↔ 第 n+1 项）。
const List<LogicalKeyboardKey> _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
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
    case 'navGuide':
      return l10n.navGuide;
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

/// 品牌字「安顿/Settle」（preview `.brand`）：普通 `text` 粗体文字，无渐变。
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
      child: Text(
        AppLocalizations.of(context)!.appTitle,
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

/// 全局快捷键 Intent（规格 §5）：`N` → 打开收集对话框。
class _CollectIntent extends Intent {
  const _CollectIntent();
}

/// 全局快捷键 Intent：切到指定全局视图索引（Ctrl/Cmd+1..9 → 侧边栏第 n 项；
/// Ctrl/Cmd+0 → 回顾 index 9）。
class _SwitchViewIntent extends Intent {
  const _SwitchViewIntent(this.index);

  /// 目标全局视图索引（0..11，对应 [_navSpecs]）。
  final int index;
}

/// 带 isEnabled 门控的 CallbackAction：文本输入焦点时禁用全局快捷键。
/// Shortcuts.handleKeypress 在 isEnabled=false 时返回 ignored，按键继续
/// 冒泡到 EditableText 正常输入（规格 §5 不拦截约束）。
///
/// **M-2 登记**：与 `task_list_view.dart` 的 `_ListShortcutAction` 是同一
/// 门控模式的 6 行重复。抽共享类需跨 `lib/app` ↔ `lib/features/task` 新建
/// 文件（layer 归属未定），超出本 Task 范围，留待收尾清单（Task 5）评估。
class _ShellAction<T extends Intent> extends CallbackAction<T> {
  _ShellAction({required super.onInvoke, this.enabled});

  final bool Function()? enabled;

  @override
  bool isEnabled(T intent) => enabled?.call() ?? true;
}
