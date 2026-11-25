import 'package:flutter/material.dart';
import 'package:gtd_app/app/theme.dart';

/// 质感拟物彩色光斑背景（规格 §7.4.3 / §7.4.4）。
///
/// 结构：底层 `linear-gradient(160deg, bg1, bg2)` 铺满 + 4 个径向渐变光斑
/// （红 / 紫 / 青 / 黄），位置 / 尺寸按预览稿的视口相对比例换算；
/// 整体被 [IgnorePointer] 包裹，不拦截任何交互。
/// 由 `GtdApp.builder` 垫底，供手机 / 桌面两套布局复用。
class SpotBackground extends StatelessWidget {
  const SpotBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<ColorSchemeExtension>();
    final bg1 = ext?.bg1 ?? const Color(0xFFDDE7FF);
    final bg2 = ext?.bg2 ?? const Color(0xFFFFE9D6);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
            ),
            child: Stack(
              children: [
                // 红 at 12% 8% ≈ 520×380：rgba(255,94,58,.55)（波1 提到 α0.6-0.7 档）
                _spot(
                  w,
                  h,
                  const Alignment(-0.76, -0.84),
                  520,
                  380,
                  const Color(0xA8FF5E3A),
                ),
                // 紫 at 88% 12% ≈ 600×420：rgba(124,61,255,.50)
                _spot(
                  w,
                  h,
                  const Alignment(0.76, -0.76),
                  600,
                  420,
                  const Color(0x997C3DFF),
                ),
                // 青 at 50% 95% ≈ 640×480：rgba(0,196,255,.45)
                _spot(
                  w,
                  h,
                  const Alignment(0.0, 0.9),
                  640,
                  480,
                  const Color(0x8C00C4FF),
                ),
                // 黄 at 82% 78% ≈ 480×360：rgba(255,214,0,.50)
                _spot(
                  w,
                  h,
                  const Alignment(0.64, 0.56),
                  480,
                  360,
                  const Color(0x99FFD600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 单个径向光斑：按视口相对中心定位（`Alignment` → 中心百分比），
  /// 尺寸为椭圆直径，渐变为「实色 → 透明 70%」（对应 CSS `transparent 70%`）。
  Widget _spot(
    double width,
    double height,
    Alignment center,
    double sizeW,
    double sizeH,
    Color color,
  ) {
    return Positioned(
      left: (center.x + 1) / 2 * width - sizeW / 2,
      top: (center.y + 1) / 2 * height - sizeH / 2,
      width: sizeW,
      height: sizeH,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}
