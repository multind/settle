# 字体族改 Microsoft YaHei UI（修复"将"字怪字形）

日期：2026-11-25
状态：已批准（用户确认修复方案）
前置：中文字体雅黑修复已收官（HEAD `7b9d421`，工作区干净）

## 1. 问题

用户反馈：gtd 应用中"将来"的"将"字字形怪异，其他应用正常。

根因：Windows 的 msyh.ttc 实际包含**两个字体族**——`Microsoft YaHei`（旧字形）
与 `Microsoft YaHei UI`（UI 专用字形）。旧版 `Microsoft YaHei` 的"将"字存在
著名怪字形；其他应用（浏览器/微信/Office）走系统字体回退时命中 `Microsoft YaHei UI`
（UI 族优先），故显示正常。当前 `theme.dart:306` 写死 `fontFamily: 'Microsoft YaHei'`
（旧族）→ 命中怪字形。系统注册表已验证：`Microsoft YaHei & Microsoft YaHei UI
(TrueType) → msyh.ttc`。

## 2. 目标

"将"字等字形改为 UI 族正常字形。

## 3. 方案

`fontFamily` 由 `'Microsoft YaHei'` 改为 `'Microsoft YaHei UI'`（单行改动）。

- 中文命中 UI 族正常字形
- 英文数字走 UI 族（拉丁字形更接近 Segoe，与 Things 3 风格更协调）
- Windows 8.1+ 均内置；Android 上不存在则回退系统默认（本就正常）
- 浅/深主题共用同一调用点，无需逐样式设置

## 4. 实现（单文件改动）

**`lib/app/theme.dart`** 第 306 行：

```dart
    fontFamily: 'Microsoft YaHei UI',
```

（注释同步为：Windows 中文 UI 族字形（"将"字等正常渲染）。）

## 5. 测试

- widget 测试不依赖字体族，96/96 应保持；`flutter analyze` 0 error。
- 真机验证：重建安装包后"将来"的"将"字字形正常。

## 6. 范围外

- 不捆绑字体文件。
- 不改字号/字重体系。
- 不处理 Android。
