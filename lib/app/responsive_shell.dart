import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:gtd_app/app/theme.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/features/contexts/contexts_page.dart';
import 'package:gtd_app/features/inbox/collect_dialog.dart';
import 'package:gtd_app/features/inbox/inbox_page.dart';
import 'package:gtd_app/features/projects/projects_page.dart';
import 'package:gtd_app/features/review/review_page.dart';
import 'package:gtd_app/features/settings/settings_page.dart';
import 'package:gtd_app/features/someday/someday_page.dart';
import 'package:gtd_app/features/today/today_page.dart';
import 'package:gtd_app/features/waiting/waiting_page.dart';

/// 响应式外壳（规格 §7.1）：LayoutBuilder 600px 断点。
/// 宽屏：NavigationRail（8 项：收件箱/今日/项目/情境/等待/将来也许/回顾/设置）；
/// 窄屏：底部 NavigationBar（5 项：收件箱/今日/项目/回顾/设置）。
class ResponsiveShell extends ConsumerStatefulWidget {
  const ResponsiveShell({super.key});

  static const double breakpoint = 600;

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    InboxPage(),
    TodayPage(),
    ProjectsPage(),
    ContextsPage(),
    WaitingPage(),
    SomedayPage(),
    ReviewPage(),
    SettingsPage(),
  ];

  // 窄屏 5 项对应的 _pages 下标：收件箱/今日/项目/回顾/设置
  static const List<int> _narrowIndices = [0, 1, 2, 6, 7];

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
                    // 玻璃侧边栏：blur(24px) → σ12，saturate(180%)，sidebar 半透明底 +
                    // 右侧 1px stroke 分隔（替代 VerticalDivider，preview `.sidebar`）。
                    _Glass(
                      sigma: 12,
                      saturation: 1.8,
                      color: tokens.sidebar,
                      border: Border(
                        right: BorderSide(color: tokens.stroke, width: 1),
                      ),
                      child: NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: (i) =>
                            setState(() => _index = i),
                        labelType: NavigationRailLabelType.all,
                        leading: const _BrandMark(),
                        destinations: _railDestinations(l10n),
                      ),
                    ),
                    Expanded(child: _pages[_index]),
                  ],
                )
              : _pages[_index],
          bottomNavigationBar: isWide
              ? null
              : _Glass(
                  sigma: 12, // blur(24px) → σ12
                  saturation: 2.0, // 规格：手机底部导航 saturate(200%)
                  color: tokens.nav,
                  border: Border(
                    top: BorderSide(color: tokens.stroke, width: 1),
                  ),
                  child: NavigationBar(
                    selectedIndex: _narrowIndices.indexOf(_index),
                    onDestinationSelected: (i) =>
                        setState(() => _index = _narrowIndices[i]),
                    destinations: _barDestinations(l10n),
                  ),
                ),
          floatingActionButton: _index != 0
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

  List<NavigationRailDestination> _railDestinations(AppLocalizations l10n) => [
        NavigationRailDestination(
          icon: const Icon(Icons.inbox_outlined),
          label: Text(l10n.navInbox),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.today),
          label: Text(l10n.navToday),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.folder_outlined),
          label: Text(l10n.navProjects),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.place_outlined),
          label: Text(l10n.navContexts),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.hourglass_empty),
          label: Text(l10n.navWaiting),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.nights_stay_outlined),
          label: Text(l10n.navSomeday),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.history),
          label: Text(l10n.navReview),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          label: Text(l10n.navSettings),
        ),
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
          icon: const Icon(Icons.folder_outlined),
          selectedIcon: const Icon(Icons.folder),
          label: l10n.navProjects,
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: l10n.navReview,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: l10n.navSettings,
        ),
      ];
}

/// 毛玻璃容器（规格 §7.4.3）：`BackdropFilter`（CSS `blur(Npx)` ≈ `sigma=N/2`）+
/// `ColorFiltered`（CSS `saturate(S)` 饱和度矩阵）。仅包裹导航条 / 侧边栏，
/// 不拦截交互。`color` 提供半透明玻璃底（`sidebar` / `nav`），`border`
/// 提供 1px stroke 分隔线（替代 VerticalDivider）。
class _Glass extends StatelessWidget {
  const _Glass({
    required this.sigma,
    required this.saturation,
    required this.child,
    this.color,
    this.border,
  });

  final double sigma;
  final double saturation;
  final Widget child;
  final Color? color;
  final Border? border;

  static const ColorFilter _saturate180 = ColorFilter.matrix(<double>[
    1.6296, -0.572, -0.0576, 0, 0, //
    -0.1704, 1.228, -0.0576, 0, 0, //
    -0.1704, -0.572, 1.7424, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  static const ColorFilter _saturate200 = ColorFilter.matrix(<double>[
    1.787, -0.715, -0.072, 0, 0, //
    -0.213, 1.285, -0.072, 0, 0, //
    -0.213, -0.715, 1.928, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ColorFiltered(
          colorFilter: saturation >= 2.0 ? _saturate200 : _saturate180,
          child: Container(
            decoration: BoxDecoration(color: color, border: border),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 品牌字「GTD」（preview `.brand`）：`linear-gradient(135deg, primary, accent)`
/// 渐变文字，Flutter 用 `ShaderMask` 实现（gradient 只作用于字形 alpha）。
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.primary, tokens.accent],
        ).createShader(bounds),
        child: const Text(
          'GTD',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
            color: Colors.white, // 颜色由 ShaderMask 替换，此处仅提供 alpha
          ),
        ),
      ),
    );
  }
}
