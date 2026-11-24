import 'package:flutter/material.dart';

/// 质感拟物双主题 token（规格 §7.4.2）。
///
/// 数值唯一来源：`preview-ui-v3.html`（CSS 变量，浅色 `:root` / 深色 `body.dark`）。
/// 透明度换算规则：CSS `rgba(r,g,b,α)` → Dart `Color(0xAA RRGGBB)`，`AA = round(α×255)`。
/// 渐变应用方向：`primary→primary2`、`accent2→accent`、`ai2→ai`（`LinearGradient` begin
/// topLeft end bottomRight，对应 CSS `135deg`）。
abstract final class AppTokens {
  static const AppTokenSet light = AppTokenSet(
    // —— 渐变端点（§7.4.2 浅色列）——
    primary: Color(0xFF2456FF),
    primary2: Color(0xFF00C2FF),
    accent2: Color(0xFF00B478),
    accent: Color(0xFF00E676),
    ai2: Color(0xFF7C3DFF),
    ai: Color(0xFFD400FF),
    // —— 文字 ——
    text: Color(0xFF141B33),
    muted: Color(0xFF5A6285),
    // —— 表面（半透明，α→round(α×255) 换算）——
    card: Color(0x99FFFFFF), // rgba(255,255,255,.60)
    cardSolid: Color(0xEBFFFFFF), // rgba(255,255,255,.92)
    stroke: Color(0xE6FFFFFF), // rgba(255,255,255,.90) 浅色下呈高光
    nav: Color(0x73FFFFFF), // rgba(255,255,255,.45)
    sidebar: Color(0x66FFFFFF), // rgba(255,255,255,.40)
    field: Color(0x8CFFFFFF), // rgba(255,255,255,.55)
    // —— 建议徽标（§7.4.3）——
    chipBg: Color(0x2900B478), // rgba(0,180,120,.16)
    chipText: Color(0xFF00775A),
    // —— 彩色投影（§7.4.2 shadow / shadow-sm）——
    shadowSmColor: Color(0x2E2456FF), // rgba(36,86,255,.18)
    shadow: [
      BoxShadow(
        color: Color(0x472456FF), // rgba(36,86,255,.28)
        blurRadius: 50,
        offset: Offset(0, 18),
      ),
      BoxShadow(
        color: Color(0x1F141B33), // rgba(20,27,51,.12)
        blurRadius: 12,
        offset: Offset(0, 4),
      ),
    ],
    shadowSm: [
      BoxShadow(color: Color(0x2E2456FF), blurRadius: 22, offset: Offset(0, 8)),
    ],
    // —— 底色渐变（§7.4.3 linear-gradient(160deg)）——
    bg1: Color(0xFFDDE7FF),
    bg2: Color(0xFFFFE9D6),
    // —— AI 元素 token（M1 定义、M2 启用，§7.4.5）——
    aiShadow: Color(0x667C3DFF), // rgba(124,61,255,.4)
    aiGlow: Color(0x59D400FF), // rgba(212,0,255,.35)
  );

  static const AppTokenSet dark = AppTokenSet(
    // —— 渐变端点（§7.4.2 深色列）——
    primary: Color(0xFF4D7DFF),
    primary2: Color(0xFF00D4FF),
    accent2: Color(0xFF00E676),
    accent: Color(0xFF00C4FF),
    ai2: Color(0xFFB388FF),
    ai: Color(0xFFFF66E5),
    // —— 文字 ——
    text: Color(0xFFEEF1FF),
    muted: Color(0xFF8F97C0),
    // —— 表面 ——
    card: Color(0x8C1C2240), // rgba(28,34,64,.55)
    cardSolid: Color(0xE61E2648), // rgba(30,38,72,.90)
    stroke: Color(0x38FFFFFF), // rgba(255,255,255,.22)
    nav: Color(0x8016222E), // rgba(16,22,46,.50)
    sidebar: Color(0x7310162E), // rgba(16,22,46,.45)
    field: Color(0x14FFFFFF), // rgba(255,255,255,.08)
    // —— 建议徽标 ——
    chipBg: Color(0x3300E676), // rgba(0,230,118,.20)
    chipText: Color(0xFF6DF7B3),
    // —— 彩色投影 ——
    shadowSmColor: Color(0x73000000), // rgba(0,0,0,.45)
    shadow: [
      BoxShadow(color: Color(0x99000000), blurRadius: 60, offset: Offset(0, 20)),
      BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 4)),
    ],
    shadowSm: [
      BoxShadow(color: Color(0x73000000), blurRadius: 28, offset: Offset(0, 10)),
    ],
    // —— 底色渐变 ——
    bg1: Color(0xFF0A0E22),
    bg2: Color(0xFF1C0F2E),
    // —— AI 元素 token（浅深两套同值，§7.4.3）——
    aiShadow: Color(0x667C3DFF),
    aiGlow: Color(0x59D400FF),
  );

  // 圆角体系两套同值（§7.4.3 末条）。
  static const double radiusContainer = 18;
  static const double radiusCard = 16;
  static const double radiusRow = 12;
  static const double radiusButton = 10;
  static const double radiusBadge = 8;
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
    // 光斑背景由 GtdApp.builder 垫底：Scaffold 透明以让背景可见（§7.4.4）。
    scaffoldBackgroundColor: Colors.transparent,
    extensions: [extension],

    // —— 组件主题挂接（§7.4.4 末条：界面代码不散写色值）——
    cardTheme: CardThemeData(
      color: tokens.cardSolid,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: tokens.shadowSmColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        side: BorderSide(color: tokens.stroke),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.nav,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: tokens.primary,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusBadge),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.white);
        }
        return IconThemeData(color: tokens.muted);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tokens.text,
          );
        }
        return TextStyle(fontSize: 12, color: tokens.muted);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: tokens.sidebar,
      elevation: 0,
      indicatorColor: tokens.primary,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
      ),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: tokens.muted),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white,
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
      backgroundColor: tokens.card,
      surfaceTintColor: Colors.transparent,
      foregroundColor: tokens.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(tokens.accent),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.15),
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
          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusBadge),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      showCheckmark: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: tokens.text,
      contentTextStyle: TextStyle(color: isLight ? Colors.white : tokens.bg1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: tokens.cardSolid,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
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
