# 中文字体指定微软雅黑（修复中文模糊）

日期：2026-11-25
状态：已批准（用户选择方案 A）
前置：Things 3 化重构已收官（HEAD `0fe6e67`，工作区干净）

## 1. 问题

用户反馈：界面中文渲染模糊。

根因：项目无任何字体配置（pubspec 无 fonts、theme 无 fontFamily）。Windows 上
Flutter 默认主字体 Segoe UI 不含中文字形，回退链常命中 SimSun（宋体）——衬线、
无 ClearType 优化，渲染发虚。与 Things 3 化视觉改动无关，是既有短板。

## 2. 目标

Windows 桌面中文改用微软雅黑清晰渲染；Android 不退化（雅黑不存在则回退系统
默认，本就清晰）。

## 3. 方案

`buildAppTheme` 中给 `ThemeData` 设置 `fontFamily: 'Microsoft YaHei'`。浅/深两套
主题共用（同一处调用点）。注意：TextTheme 由 `base.textTheme.apply` 生成，需确认
fontFamily 从 ThemeData 传导到 TextTheme（MaterialApp 会在 buildTextTheme 时把
theme.fontFamily 应用到无显式 fontFamily 的样式——标准机制，无需逐样式设置）。

英文/数字随雅黑渲染，观感协调（17px/w600 标题配合良好），可接受。

## 4. 实现（单文件改动）

**`lib/app/theme.dart`** 的 `buildAppTheme`（约第 271-473 行一带，ThemeData 构造
处）添加：

```dart
fontFamily: 'Microsoft YaHei',
```

位置：与 `scaffoldBackgroundColor` 同级（ThemeData 顶层参数）。以实际代码为准
确认 ThemeData 构造参数里无重复 fontFamily。

## 5. 测试

- widget 测试不依赖字体族，96/96 应保持；`flutter analyze` 0 error。
- 真机验证：重建安装包后中文（含任务行/设置页/对话框）渲染清晰，无发虚。

## 6. 范围外

- 不捆绑字体文件（方案 B 未选）。
- 不改字号/字重体系。
- 不处理 Android（本就清晰）。
