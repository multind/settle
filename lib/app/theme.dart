import 'package:flutter/material.dart';

/// Things 3 化双主题 token（v0.2 视觉规范）。
///
/// 纯底无装饰：浅=纯白底/深=纯黑底，主色 Things 蓝（浅 #3D7CFB / 深 #4D8CFF），
/// 阴影/渐变/玻璃元素已全部移除，靠 hairline 分隔与留白组织界面。
abstract final class AppTokens {
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
    selectedBg: Color(0xFFF2F4FA), // 浅色：浅蓝灰
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
    selectedBg: Color(0xFF1C1C1E),
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

  // 圆角体系（Things 3 小圆角）。
  static const double radiusContainer = 8;
  static const double radiusCard = 8;
  static const double radiusRow = 8;
  static const double radiusButton = 6;
  static const double radiusBadge = 8;
  static const double radiusField = 8;
}

/// 单套主题 token 集合：由 [AppTokens.light] / [AppTokens.dark] 两个 const 实例承载。
class AppTokenSet {
  const AppTokenSet({
    required this.primary,
    required this.primary2,
    required this.accent2,
    required this.accent,
    required this.ai2,
    required this.ai,
    required this.text,
    required this.muted,
    required this.card,
    required this.selectedBg,
    required this.cardSolid,
    required this.stroke,
    required this.nav,
    required this.sidebar,
    required this.field,
    required this.chipBg,
    required this.chipText,
    required this.shadowSmColor,
    required this.shadow,
    required this.shadowSm,
    required this.bg1,
    required this.bg2,
    required this.aiShadow,
    required this.aiGlow,
  });

  final Color primary;
  final Color primary2;
  final Color accent2;
  final Color accent;
  final Color ai2;
  final Color ai;
  final Color text;
  final Color muted;
  final Color card;
  final Color selectedBg;
  final Color cardSolid;
  final Color stroke;
  final Color nav;
  final Color sidebar;
  final Color field;
  final Color chipBg;
  final Color chipText;
  final Color shadowSmColor;
  final List<BoxShadow> shadow;
  final List<BoxShadow> shadowSm;
  final Color bg1;
  final Color bg2;
  final Color aiShadow;
  final Color aiGlow;
}

/// 双主题扩展字段（§7.4.4）：渐变端点与 AI / 徽标 / 底色 token，
/// 供 M2 起界面代码经 `Theme.of(context).extension<ColorSchemeExtension>()` 直接引用。
class ColorSchemeExtension extends ThemeExtension<ColorSchemeExtension> {
  const ColorSchemeExtension({
    required this.primary2,
    required this.accent2,
    required this.ai,
    required this.ai2,
    required this.aiShadow,
    required this.aiGlow,
    required this.chipBg,
    required this.chipText,
    required this.bg1,
    required this.bg2,
    required this.muted,
    required this.text,
  });

  final Color primary2;
  final Color accent2;
  final Color ai;
  final Color ai2;
  final Color aiShadow;
  final Color aiGlow;
  final Color chipBg;
  final Color chipText;
  final Color bg1;
  final Color bg2;
  final Color muted;
  final Color text;

  @override
  ColorSchemeExtension copyWith({
    Color? primary2,
    Color? accent2,
    Color? ai,
    Color? ai2,
    Color? aiShadow,
    Color? aiGlow,
    Color? chipBg,
    Color? chipText,
    Color? bg1,
    Color? bg2,
    Color? muted,
    Color? text,
  }) {
    return ColorSchemeExtension(
      primary2: primary2 ?? this.primary2,
      accent2: accent2 ?? this.accent2,
      ai: ai ?? this.ai,
      ai2: ai2 ?? this.ai2,
      aiShadow: aiShadow ?? this.aiShadow,
      aiGlow: aiGlow ?? this.aiGlow,
      chipBg: chipBg ?? this.chipBg,
      chipText: chipText ?? this.chipText,
      bg1: bg1 ?? this.bg1,
      bg2: bg2 ?? this.bg2,
      muted: muted ?? this.muted,
      text: text ?? this.text,
    );
  }

  @override
  ColorSchemeExtension lerp(ColorSchemeExtension? other, double t) {
    if (other == null) return this;
    return ColorSchemeExtension(
      primary2: Color.lerp(primary2, other.primary2, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      ai: Color.lerp(ai, other.ai, t)!,
      ai2: Color.lerp(ai2, other.ai2, t)!,
      aiShadow: Color.lerp(aiShadow, other.aiShadow, t)!,
      aiGlow: Color.lerp(aiGlow, other.aiGlow, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      chipText: Color.lerp(chipText, other.chipText, t)!,
      bg1: Color.lerp(bg1, other.bg1, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ColorSchemeExtension &&
        other.primary2 == primary2 &&
        other.accent2 == accent2 &&
        other.ai == ai &&
        other.ai2 == ai2 &&
        other.aiShadow == aiShadow &&
        other.aiGlow == aiGlow &&
        other.chipBg == chipBg &&
        other.chipText == chipText &&
        other.bg1 == bg1 &&
        other.bg2 == bg2 &&
        other.muted == muted &&
        other.text == text;
  }

  @override
  int get hashCode => Object.hashAll([
        primary2,
        accent2,
        ai,
        ai2,
        aiShadow,
        aiGlow,
        chipBg,
        chipText,
        bg1,
        bg2,
        muted,
        text,
      ]);
}

/// 按 token 手工构造浅 / 深两套 `ThemeData`（规格 §7.4.4，非 `ColorScheme.fromSeed`）。
ThemeData buildAppTheme(Brightness brightness) {
  final bool isLight = brightness == Brightness.light;
  final tokens = isLight ? AppTokens.light : AppTokens.dark;
  final extension = ColorSchemeExtension(
    primary2: tokens.primary2,
    accent2: tokens.accent2,
    ai: tokens.ai,
    ai2: tokens.ai2,
    aiShadow: tokens.aiShadow,
    aiGlow: tokens.aiGlow,
    chipBg: tokens.chipBg,
    chipText: tokens.chipText,
    bg1: tokens.bg1,
    bg2: tokens.bg2,
    muted: tokens.muted,
    text: tokens.text,
  );

  final scheme = ColorScheme(
    brightness: brightness,
    primary: tokens.primary,
    onPrimary: Colors.white,
    primaryContainer: tokens.primary2,
    onPrimaryContainer: Colors.white,
    secondary: tokens.accent,
    onSecondary: Colors.white,
    secondaryContainer: tokens.accent2,
    onSecondaryContainer: Colors.white,
    error: isLight ? const Color(0xFFB3261E) : const Color(0xFFF2B8B5),
    onError: isLight ? Colors.white : const Color(0xFF141B33),
    surface: tokens.card,
    onSurface: tokens.text,
    onSurfaceVariant: tokens.muted,
    surfaceContainerLowest: tokens.card,
    surfaceContainerLow: tokens.card,
    surfaceContainer: tokens.card,
    surfaceContainerHigh: tokens.cardSolid,
    surfaceContainerHighest: tokens.cardSolid,
    outline: tokens.stroke,
    outlineVariant: tokens.stroke,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    // 纯色背景由主题 token 提供（Things 3 极简纯底，无光斑/渐变）。
    scaffoldBackgroundColor: tokens.bg1,
    extensions: [extension],

    // —— 组件主题挂接（§7.4.4 末条：界面代码不散写色值）——
    cardTheme: CardThemeData(
      color: tokens.cardSolid,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        side: BorderSide(color: tokens.stroke),
      ),
    ),
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
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: tokens.primary,
          );
        }
        return TextStyle(fontSize: 12, color: tokens.muted);
      }),
    ),
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.field,
      labelStyle: TextStyle(color: tokens.muted),
      hintStyle: TextStyle(color: tokens.muted),
      prefixIconColor: tokens.muted,
      suffixIconColor: tokens.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        borderSide: BorderSide(color: tokens.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        borderSide: BorderSide(color: tokens.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
        borderSide: BorderSide(color: tokens.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: tokens.bg1,
      surfaceTintColor: Colors.transparent,
      foregroundColor: tokens.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // Things 3 标题：17px 中等字重，无光晕。
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: tokens.text,
      ),
    ),
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
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(tokens.text),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
        ),
      ),
    ),
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
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.text.withValues(alpha: 0.92),
      contentTextStyle: TextStyle(color: tokens.bg1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusRow),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.cardSolid,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusContainer),
        side: BorderSide(color: tokens.stroke),
      ),
    ),
    dividerTheme: DividerThemeData(color: tokens.stroke),
    listTileTheme: ListTileThemeData(
      iconColor: tokens.muted,
      textColor: tokens.text,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: tokens.primary,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.primary),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: tokens.primary,
      selectionColor: tokens.primary.withValues(alpha: 0.30),
      selectionHandleColor: tokens.primary,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: tokens.text,
      displayColor: tokens.text,
    ),
  );
}
