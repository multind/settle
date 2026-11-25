# Things 3 化视觉重构实施计划（v0.2）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 gtd_app 视觉彻底对标 Things 3（极简/留白/纯底/hairline 分隔/Things 蓝），删除质感拟物元素（毛玻璃/渐变/光斑/彩色阴影/品牌渐变字）。

**Architecture:** 核心策略——`glass.dart` 三个组件**保留构造签名、内部去掉 blur/saturate/彩色阴影/渐变**（页面 14+7+4 处引用零改动），`theme.dart` token 重写（cardSolid/shadowSm 等改纯值使页面传参自动失效），删除 `SpotBackground` 与 shell `_Glass`/渐变品牌字，收集框改输入框风格。测试 Key/文案/结构断言全部保留。

**Tech Stack:** Flutter 3.50、flutter_test（widget 96/96 基线）。

**Spec:** `docs/superpowers/specs/2026-11-25-things3-ui-redesign-design.md`

---

### Task 1: theme.dart token 重写 + 组件主题 Things 3 化

**Files:**
- Modify: `lib/app/theme.dart`

- [x] **Step 1: 重写 AppTokens.light** ✅ 42c0451

将 `lib/app/theme.dart` 第 10-54 行（`light` 常量体）替换为：

```dart
  static const AppTokenSet light = AppTokenSet(
    // —— 主色（Things 3 蓝）——
    primary: Color(0xFF3D7CFB),
    primary2: Color(0xFF3D7CFB),
    accent2: Color(0xFF3D7CFB),
    accent: Color(0xFF3D7CFB),
    ai2: Color(0xFF3D7CFB),
    ai: Color(0xFF3D7CFB),
    // —— 文字 ——
    text: Color(0xFF1A1A1A),
    muted: Color(0xFF8A8A8E),
    // —— 表面（纯色，非半透明）——
    card: Color(0xFFFFFFFF),
    cardSolid: Color(0xFFFFFFFF),
    stroke: Color(0xFFE5E5EA),
    nav: Color(0xFFFFFFFF),
    sidebar: Color(0xFFFFFFFF),
    field: Color(0xFFF5F5F7),
    // —— 徽标（灰字细描边）——
    chipBg: Color(0xFFF5F5F7),
    chipText: Color(0xFF8A8A8E),
    // —— 阴影（全部移除）——
    shadowSmColor: Color(0x00000000),
    shadow: [],
    shadowSm: [],
    // —— 背景（纯白，无渐变）——
    bg1: Color(0xFFFFFFFF),
    bg2: Color(0xFFFFFFFF),
    // —— AI 元素 token（M1 定义 M2 启用，主色占位）——
    aiShadow: Color(0x00000000),
    aiGlow: Color(0x00000000),
  );
```

- [x] **Step 2: 重写 AppTokens.dark** ✅ 42c0451

将第 56-92 行（`dark` 常量体）替换为：

```dart
  static const AppTokenSet dark = AppTokenSet(
    // —— 主色（Things 3 蓝，深色提亮）——
    primary: Color(0xFF4D8CFF),
    primary2: Color(0xFF4D8CFF),
    accent2: Color(0xFF4D8CFF),
    accent: Color(0xFF4D8CFF),
    ai2: Color(0xFF4D8CFF),
    ai: Color(0xFF4D8CFF),
    // —— 文字 ——
    text: Color(0xFFF5F5F7),
    muted: Color(0xFF8E8E93),
    // —— 表面（纯黑系）——
    card: Color(0xFF000000),
    cardSolid: Color(0xFF000000),
    stroke: Color(0xFF2C2C2E),
    nav: Color(0xFF000000),
    sidebar: Color(0xFF000000),
    field: Color(0xFF1C1C1E),
    // —— 徽标 ——
    chipBg: Color(0xFF1C1C1E),
    chipText: Color(0xFF8E8E93),
    // —— 阴影（全部移除）——
    shadowSmColor: Color(0x00000000),
    shadow: [],
    shadowSm: [],
    // —— 背景（纯黑）——
    bg1: Color(0xFF000000),
    bg2: Color(0xFF000000),
    // —— AI 元素 token ——
    aiShadow: Color(0x00000000),
    aiGlow: Color(0x00000000),
  );
```

- [x] **Step 3: 圆角体系收小** ✅ 42c0451

将第 94-100 行替换为：

```dart
  // 圆角体系（Things 3 小圆角）。
  static const double radiusContainer = 8;
  static const double radiusCard = 8;
  static const double radiusRow = 8;
  static const double radiusButton = 6;
  static const double radiusBadge = 8;
```

- [x] **Step 4: 组件主题 Things 3 化（buildAppTheme）** ✅ 42c0451

逐块替换 `buildAppTheme`（第 271-513 行）中的组件主题：

**CardTheme**（第 323-334 行）替换为：
```dart
    cardTheme: CardThemeData(
      color: tokens.cardSolid,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        side: BorderSide(color: tokens.stroke),
      ),
    ),
```

**NavigationRailTheme**（第 361-382 行）替换为：
```dart
    navigationRailTheme: NavigationRailThemeData(
      // Things 3 侧边栏：纯底 + hairline 分隔（分隔由 shell 提供）。
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: tokens.selectedBg,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
      ),
      selectedIconTheme: IconThemeData(color: tokens.primary),
      unselectedIconTheme: IconThemeData(color: tokens.muted),
      selectedLabelTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: tokens.primary,
      ),
      unselectedLabelTextStyle: TextStyle(fontSize: 12, color: tokens.muted),
    ),
```

> 注意：`tokens.selectedBg` 为新增字段，见 Step 5。

**NavigationBarTheme**（第 335-360 行）替换为：
```dart
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: tokens.selectedBg,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: tokens.primary);
        }
        return IconThemeData(color: tokens.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tokens.primary);
        }
        return TextStyle(fontSize: 12, color: tokens.muted);
      }),
    ),
```

**AppBarTheme**（第 404-421 行）替换为：
```dart
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: tokens.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: tokens.text,
      ),
    ),
```

**FilledButtonTheme**（第 422-442 行）替换为：
```dart
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(tokens.primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.1),
        ),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    ),
```

**ChipTheme**（第 456-469 行）替换为：
```dart
    chipTheme: ChipThemeData(
      backgroundColor: tokens.chipBg,
      labelStyle: TextStyle(
        color: tokens.chipText,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: tokens.stroke),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusBadge),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      showCheckmark: false,
    ),
```

**DialogTheme**（第 478-489 行）替换为：
```dart
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.cardSolid,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
        side: BorderSide(color: tokens.stroke),
      ),
    ),
```

**SnackBarTheme**（第 470-477 行）替换为：
```dart
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.text.withValues(alpha: 0.92),
      contentTextStyle: TextStyle(color: tokens.bg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
      ),
    ),
```

**scaffoldBackgroundColor**（第 319 行）改为：
```dart
    scaffoldBackgroundColor: tokens.bg,
```

- [x] **Step 5: AppTokenSet 新增 selectedBg 字段** ✅ 42c0451

在 `AppTokenSet`（第 103-153 行）中新增字段。构造参数在 `card` 之后插入 `required this.selectedBg,`，字段声明在 `final Color card;` 之后插入 `final Color selectedBg;`。并在 `light`/`dark` 常量体中（`cardSolid` 行后）各插入：

```dart
    selectedBg: Color(0xFFF2F4FA), // 浅色：浅蓝灰
```

（深色为 `selectedBg: Color(0xFF1C1C1E),`）

- [x] **Step 6: analyze** ✅ 42c0451（0 error）

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/app/theme.dart
```

Expected: 0 error（SDK 级 material.dart 弃用 info 除外）。

- [x] **Step 7: 提交** ✅ 42c0451（工作区干净）

```powershell
git add lib/app/theme.dart
git commit -m "refactor(theme): Things 3 化 token 与组件主题（删渐变/玻璃/彩色阴影）"
```

---

### Task 2: glass.dart 组件 Things 3 化（保留签名）

**Files:**
- Modify: `lib/app/glass.dart`

- [x] **Step 1: GlassContainer 去模糊/饱和度/彩色阴影** ✅ 8d8b408（child 外包 transparency Material，官方修复 ListTile 墨迹断言）

将 `GlassContainer` 类（第 52-127 行）的 build 方法替换为纯描边容器（构造参数**全部保留**，忽略 blur/saturate）：

```dart
  @override
  Widget build(BuildContext context) {
    final Border? border =
        borderColor == null ? null : Border.all(color: borderColor!);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadow,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
```

（`blur`/`saturate` 字段保留声明不再使用——页面传参继续有效，视觉为纯底描边。）

- [x] **Step 2: GradientButton 改实色 primary** ✅ 8d8b408

将 `GradientButton` build（第 162-216 行）替换为实色按钮（构造参数保留，忽略 gradient/glow）：

```dart
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final button = Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            child: child,
          ),
        ),
      ),
    );
    if (minimumSize == null) return button;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimumSize!.width,
        minHeight: minimumSize!.height,
      ),
      child: button,
    );
  }
```

- [x] **Step 3: GlassCheckbox 改实心圆勾** ✅ 8d8b408

将 `GlassCheckbox` build（第 234-278 行）替换为 Things 3 风格（选中=primary 实心圆+白✓、未选=描边圆）：

```dart
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? scheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: value
              ? null
              : Border.all(color: scheme.primary, width: 1.5),
        ),
        child: value
            ? const Center(
                child: Icon(Icons.check, size: 12, color: Colors.white),
              )
            : null,
      ),
    );
  }
```

- [x] **Step 4: 清理文件头注释与未用代码** ✅ 8d8b408（删 dart:ui import/饱和度矩阵/_saturationFilter；theme.dart 头注释修正）

删除第 15-42 行（饱和度矩阵常量与 `_saturationFilter`）以及 `import 'dart:ui' show ImageFilter;`（第 1 行），文件头注释改为：

```dart
/// Things 3 化可复用组件（v0.2 视觉规范）。
///
/// 保留构造签名以兼容既有页面调用：`GlassContainer` 为纯底描边容器、
/// `GradientButton` 为实色主按钮、`GlassCheckbox` 为实心圆勾完成钮。
/// 不再使用 blur / saturate / 渐变 / 彩色阴影（质感拟物元素已移除）。
```

- [x] **Step 5: analyze + 关键测试** ✅ 8d8b408（0 error；关键 9/9 + 全量 96/96）

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze lib/app/glass.dart lib/app/theme.dart
flutter test test/widget/quick_collect_test.dart test/widget/inbox_page_test.dart test/widget/today_page_test.dart
```

Expected: analyze 0 error；测试全绿（组件签名未变，页面零改动）。

- [x] **Step 6: 提交**

```powershell
git add lib/app/glass.dart
git commit -m "refactor(glass): 组件 Things 3 化（纯描边容器/实色按钮/实心圆勾，签名兼容）"
```

---

### Task 3: 删 SpotBackground + shell 去玻璃去渐变

**Files:**
- Delete: `lib/app/spot_background.dart`
- Modify: `lib/app/app.dart:27`
- Modify: `lib/app/responsive_shell.dart`

- [x] **Step 1: 删除 spot_background.dart** ✅ 9b5a5ae

```powershell
git rm lib/app/spot_background.dart
```

- [x] **Step 2: 移除 app.dart 中的 SpotBackground 引用** ✅ 9b5a5ae

读取 `lib/app/app.dart`，移除 builder 中的 `Positioned.fill(child: SpotBackground())` 包裹与相关 import、const 调整——将 Scaffold 包装改为直接返回 child（保持 GtdApp 其余逻辑不变）。改后结构应为：

```dart
  // 纯色背景由主题 scaffoldBackgroundColor 提供，无需额外背景组件。
```

具体以实际代码为准：删除 `SpotBackground` 的 import、删除 builder 内 Stack/Positioned.fill 包裹（若 Stack 无其他子项则直接返回 body）。

- [x] **Step 3: shell 去 _Glass 换纯底分隔** ✅ 9b5a5ae

`lib/app/responsive_shell.dart`：
- 删除 `import 'dart:ui' show ImageFilter;`（第 1 行）
- 宽屏侧边栏（第 59-74 行）：`_Glass(...)` 替换为 `Container(color: tokens.sidebar, child: ..., )` 保留右侧 1px stroke 分隔（用 `Container` + `Border(right: BorderSide(color: tokens.stroke, width: 1))`，child 为原 NavigationRail）
- 窄屏底部导航（第 81-94 行）：`_Glass(...)` 替换为 `Container(color: tokens.nav, child: ..., )` 保留顶部 1px stroke 分隔
- 删除 `_Glass` 类（第 179-223 行）与饱和度矩阵常量（第 194-206 行）
- 若 NavigationBar 背景不再透明（无 BackdropFilter），确认 `Container` 用不透明 `tokens.nav`（=bg 纯色）

- [x] **Step 4: 品牌字去渐变** ✅ 9b5a5ae

`_BrandMark`（第 227-255 行）替换为普通文字（删 ShaderMask）：

```dart
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
```

- [x] **Step 5: 测试** ✅ 9b5a5ae（6/6 目标 + 全量 96/96）

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test test/widget/responsive_shell_test.dart test/widget/app_smoke_test.dart
```

Expected: 全绿（NavigationRail/Bar 类型与 8/5 项计数保留；FAB 互斥条件未动）。

- [x] **Step 6: 提交** ✅ 9b5a5ae（3 files：app.dart/shell/删 spot_background）

---

### Task 4: 收集框输入框化 + 收集对话框适配

**Files:**
- Modify: `lib/features/inbox/quick_collect_bar.dart`
- Modify: `lib/features/inbox/collect_dialog.dart`

- [x] **Step 1: quick_collect_bar 改输入框风格** ✅ 2ae05d7

将 `_QuickCollectBarState.build`（第 40-112 行）的 Container 渐变装饰替换为 Things 3 输入框（`fieldBg` 填充 + `stroke` 描边 + 圆角 8），文字/hint 用 `text`/`muted`（不再白色），提交钮改实色 primary 圆钮：

```dart
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
```

> `AppTokens.radiusField` 需新增（Task 1 未加，见下方 Task 4 Step 2 注记）。文件头注释同步改为 Things 3 输入框说明。移除 `ext`/`accent2`/`accent` 变量（不再使用），相关 import 若不再引用则删除。

- [x] **Step 2: 新增 radiusField token** ✅ 2ae05d7

`lib/app/theme.dart` 圆角体系（Task 1 Step 3 之后）追加一行：

```dart
  static const double radiusField = 8;
```

- [x] **Step 3: collect_dialog 适配（组件改造后自动，仅检查注释/背景）** ✅ 2ae05d7

读取 `lib/features/inbox/collect_dialog.dart`：`GlassContainer` 与 `GradientButton` 已由 Task 2 改造自动生效（纯底+实色），无需逻辑改动；仅将文件头注释（第 11-12 行）同步为 Things 3 化描述。若其中有 `scheme.surface` 等残留取值逻辑，确认与纯色主题不冲突（不改 Key/逻辑）。

- [x] **Step 4: 测试** ✅ 2ae05d7（注：原文引用的 `collect_dialog_test.dart` 不存在，对话框断言在 `quick_collect_test.dart`，已修正路径；关键 3/3 + 全量 96/96）

Expected: 全绿（`quick_collect_field/button`、`collect_dialog_field/submit` Key 保留）。

- [x] **Step 5: 提交** ✅ 2ae05d7（工作区干净）

---

### Task 5: 页面层徽标/细节 Things 3 化

**Files:**
- Modify: `lib/features/inbox/inbox_page.dart`（徽标硬编码）
- 其余页面**零改动**（GlassContainer/GradientButton/GlassCheckbox 改造自动生效）

- [x] **Step 1: inbox 状态徽标改灰字细描边** ✅ 4825003

`lib/features/inbox/inbox_page.dart` 第 72-85 行的状态 Chip 替换为（去掉琥珀/绿玻璃底，改灰字细描边）：

```dart
          Chip(
            label: Text(isPending ? l10n.statusPending : l10n.statusClarified),
            visualDensity: VisualDensity.compact,
            labelStyle: TextStyle(
              color: tokens.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
```

（`isLight`/`tokens` 变量若该处不再使用则检查清理，其余保持不变。）

- [x] **Step 2: 全量回归** ✅ 4825003（96/96）

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（96/96）。

- [x] **Step 3: analyze 全仓** ✅ 4825003（0 error，无新增 warning）

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze 2>&1 | Select-String -Pattern 'error' | Select-Object -First 5
```

Expected: 0 error（58 条既有 info/warning 基线除外）。

- [x] **Step 4: 提交** ✅ 4825003（含 I1 投影修复；工作区干净）

```powershell
git add lib/features/inbox/inbox_page.dart
git commit -m "refactor(inbox): 状态徽标 Things 3 化（灰字细描边）"
```

---

### Task 6: 重建安装包 + 截图确认

**Files:**
- 产物：`dist\gtd_app-setup-0.1.1.exe`

- [x] **Step 1: 清理并构建** ✅（release 157.8s）
- [x] **Step 2: 打包** ✅（ISCC Successful，产物 15:48:36）

- [x] **Step 3: 启动 + 截图（浅色）** ✅ things3-light.png（直方图 83% 纯白 + #3D7CFB 蓝，token 吻合）
- [x] **Step 4: 截图（深色，可选）** ✅ things3-dark.png（#000000 底 85% + #4D8CFF，token 吻合）
- [x] **Step 5: 工作区确认** ✅ 干净

---

## 自审记录

- **Spec 覆盖**：§3 token→Task 1；§4 组件规则（卡片/按钮/完成钮/徽标/品牌字/收集框/导航）→Tasks 1-5；§5 文件清单→Tasks 1-5；§6 测试硬约束→各 Task 测试步骤；§7 验证→Task 6。完整覆盖。
- **占位符扫描**：无 TBD/TODO；代码块完整给出（Task 3 Step 2 app.dart 因原文件未全文读取，标注"以实际代码为准"并给出目标结构——实施者需先读文件）。
- **类型一致性**：`tokens.selectedBg` 在 Task 1 Step 5 新增、Task 1 Step 4 使用，顺序正确；`AppTokens.radiusField` 在 Task 4 Step 2 新增、Step 1 使用，顺序正确；GlassContainer/GradientButton/GlassCheckbox 构造签名全程未变（页面引用兼容）。
