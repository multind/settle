import 'package:flutter/material.dart';
import 'package:settle_app/app/theme.dart';

/// Things 3 化可复用组件（v0.2 视觉规范）。
///
/// 保留构造签名以兼容既有页面调用：`GlassContainer` 为纯底描边容器、
/// `GradientButton` 为实色主按钮、`GlassCheckbox` 为实心圆勾完成钮。
/// 不再使用 blur / saturate / 渐变 / 彩色阴影（质感拟物元素已移除）。

/// 纯底描边容器（原玻璃容器）。
///
/// 保留 `blur` / `saturate` / `shadow` 构造参数仅作兼容占位（不再产生任何
/// 视觉效果）；渲染为纯色底 + 可选 hairline 描边（0 阴影）。
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.color,
    required this.child,
    this.blur = 12,
    this.saturate = 1.8,
    this.borderColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.shadow,
    this.padding,
  });

  /// 底色。
  final Color color;

  /// 兼容占位：背景模糊 sigma（已不再生效）。
  final double blur;

  /// 兼容占位：饱和度（已不再生效）。
  final double saturate;

  /// 描边色（如 `stroke`），null 则不描边。
  final Color? borderColor;

  final BorderRadius borderRadius;

  /// 兼容占位：外层投影（已不再生效，0 阴影）。
  final List<BoxShadow>? shadow;

  final EdgeInsetsGeometry? padding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Border? border =
        borderColor == null ? null : Border.all(color: borderColor!);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
        // 0 阴影：不再渲染 shadow（规格 §3「全部彩色阴影移除」）。
      ),
      // 透明 Material：防止 ListTile 断言「背景色 DecoratedBox 包裹会隐藏
      // 墨迹/背景」（Flutter 官方建议的修复），渲染效果不变。
      child: Material(
        type: MaterialType.transparency,
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// 实色主按钮（原渐变主按钮）。
///
/// 保留 `gradient` / `glow` 构造参数仅作兼容占位（不再产生任何视觉效果）；
/// 渲染为 `ColorScheme.primary` 实底 + 白色文字，`onPressed == null` 时禁点。
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.gradient,
    this.glow = const Color(0x6600B478), // rgba(0,180,120,.40)
    this.radius = AppTokens.radiusButton,
    this.padding,
    this.minimumSize,
  });

  final VoidCallback? onPressed;
  final Widget child;

  /// 兼容占位：渐变颜色列表（已不再生效）。
  final List<Color>? gradient;

  /// 兼容占位：光晕色（已不再生效）。
  final Color glow;

  final double radius;

  final EdgeInsetsGeometry? padding;

  final Size? minimumSize;

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
}

/// 实心圆勾完成钮（原玻璃复选框）：选中 = `primary` 实心圆 + 白 ✓，
/// 未选 = `primary` 描边圆。`onChanged == null` 时禁点。
class GlassCheckbox extends StatelessWidget {
  const GlassCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 18,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

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
}
