import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:gtd_app/app/theme.dart';

/// 质感拟物可复用玻璃 / 渐变组件（规格 §7.4.3）。
///
/// 数值换算规则（§7.4.4）：CSS `blur(Npx)` → sigma = N/2；`saturate(S%)` →
/// 亮度保持型饱和度矩阵（与 CSS `saturate()` 语义一致，也是 shell 内 `_Glass`
/// 已在用的矩阵）；阴影 `rgba(r,g,b,α)` → `Color(0xAA RRGGBB)`，`AA = round(α×255)`；
/// `135deg` 渐变 → `LinearGradient(begin: topLeft, end: bottomRight)`。
///
/// 本文件组件供波 1（渐变收集框 / 玻璃收集对话框）与波 2（页面行 / 完成钮）复用。

/// 饱和度矩阵常量：1.8 ↔ saturate(180%)，2.0 ↔ saturate(200%)，1.0 ↔ 恒等。
/// 亮度保持型：饱和度提升不改变明度，避免对角放大带来的过曝 / 偏灰。
const List<double> _saturate180 = <double>[
  1.6296, -0.572, -0.0576, 0, 0, //
  -0.1704, 1.228, -0.0576, 0, 0, //
  -0.1704, -0.572, 1.7424, 0, 0, //
  0, 0, 0, 1, 0,
];

const List<double> _saturate200 = <double>[
  1.787, -0.715, -0.072, 0, 0, //
  -0.213, 1.285, -0.072, 0, 0, //
  -0.213, -0.715, 1.928, 0, 0, //
  0, 0, 0, 1, 0,
];

const List<double> _saturate100 = <double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0,
];

ColorFilter _saturationFilter(double saturate) {
  if (saturate >= 2.0) return const ColorFilter.matrix(_saturate200);
  if (saturate <= 1.0) return const ColorFilter.matrix(_saturate100);
  return const ColorFilter.matrix(_saturate180);
}

/// 玻璃容器：`ClipRRect` + `BackdropFilter(blur)` + `ColorFiltered(saturate)`。
///
/// 三层 Stack 结构：
/// - 底层：半透明底色（玻璃色调，如 `card` / `sidebar` / `nav`）；
/// - 中层：`BackdropFilter` blur + `ColorFiltered` 饱和度 —— 只作用于背景与底色，
///   让「模糊后有内容」成立，**不会把 child 文字也饱和变色**；
/// - 顶层：内容 + 高光描边（描边在 blur 之上绘制，保持 1px 锐利，不被模糊吃掉）。
/// 投影放在最外层，因此不参与 blur / 饱和度，保持清晰的彩色阴影。
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

  /// 半透明底色（玻璃色调）。
  final Color color;

  /// 背景模糊 sigma（CSS `blur(2σ px)`）。
  final double blur;

  /// 饱和度：1.0 / 1.8 / 2.0。
  final double saturate;

  /// 高光描边色（如 `stroke`），null 则不描边。
  final Color? borderColor;

  final BorderRadius borderRadius;

  /// 外层投影（`List<BoxShadow>`，不被 blur / 饱和度影响）。
  final List<BoxShadow>? shadow;

  final EdgeInsetsGeometry? padding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Border? border =
        borderColor == null ? null : Border.all(color: borderColor!);
    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // 底层：玻璃底色（铺满 Stack 尺寸）
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
            // 中层：blur + 饱和度（铺满 Stack 尺寸，child 不受影响）。
            // 注意不用 StackFit.expand：对话框等松约束场景下会让内容撑满
            // 最大可用尺寸，必须让 Stack 随内容收缩、背景层用 Positioned.fill。
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: _saturationFilter(saturate),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // 顶层：内容 + 高光描边（描边在 blur 之上绘制，保持 1px 锐利）
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: border,
              ),
              child: padding == null
                  ? child
                  : Padding(padding: padding!, child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// 渐变主按钮（规格 §7.4.3 `.btn-go`）：accent2→accent 渐变底 + 白色文字 +
/// 彩色光晕 + 圆角 10。浅 / 深主题色经 `ColorSchemeExtension` 取（缺省回退
/// `ColorScheme.secondary`，保证测试环境下不依赖扩展也能用）。
///
/// 涟漪：`Material(color: transparent)` + `Ink(gradient)` + `InkWell`，
/// 使水波纹绘制在渐变之上（Flutter 渐变按钮的标准做法）。
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

  /// 渐变颜色列表；缺省 accent2→accent。
  final List<Color>? gradient;

  /// 光晕色：`0 6px 16px` 的 `Color(0x6600B478)`。
  final Color glow;

  final double radius;

  final EdgeInsetsGeometry? padding;

  final Size? minimumSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<ColorSchemeExtension>();
    final colors = gradient ??
        <Color>[
          ext?.accent2 ?? const Color(0xFF00B478),
          scheme.secondary,
        ];
    final borderRadius = BorderRadius.circular(radius);
    final button = Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: borderRadius,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            child: Padding(
              padding:
                  padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                child: child,
              ),
            ),
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

/// 玻璃复选框（18×18，圆角 6）：未选 `2px solid primary` + 蓝色微光；
/// 选中 accent2→accent 渐变底 + 白色 ✓ + 绿色光晕。供波 2 任务行完成钮复用。
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
    final ext = Theme.of(context).extension<ColorSchemeExtension>();
    final accent2 = ext?.accent2 ?? const Color(0xFF00B478);
    final accent = scheme.secondary;
    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? null : Colors.transparent,
          gradient: value
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent2, accent],
                )
              : null,
          borderRadius: BorderRadius.circular(6),
          border: value ? null : Border.all(color: scheme.primary, width: 2),
          boxShadow: value
              ? const [
                  BoxShadow(
                    color: Color(0x8000B478), // rgba(0,180,120,.5)
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
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
