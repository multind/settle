# 字体族改思源黑体 Noto Sans SC（Skia 下渲染优于雅黑）

日期：2026-11-25
状态：已批准（用户确认方案 A）
前置：YaHei UI 修复已收官（HEAD `ef11e80`，工作区干净）

## 1. 背景与问题

用户对微软雅黑整体不满意。诊断：
- 微信 Windows 版用的也是微软雅黑（系统字体），观感差异来自渲染引擎——微信/浏览器走
  DirectWrite + ClearType（雅黑有专门 hinting 优化），Flutter 走 Skia 自绘渲染，
  对雅黑渲染偏虚。**引擎层面无法复刻**。
- 换字体族可显著改善：思源黑体（Noto Sans SC，Google/Adobe 开源 OFL）字形现代、
  笔画标准（"将"字等无怪字形）、**在 Skia 渲染下口碑远好于雅黑**。

## 2. 关键事实

系统注册表已确认用户 Windows **已安装** Noto Sans SC（可变字体 VF）：

```
Noto Sans SC (TrueType)  →  NotoSansSC-VF.ttf
```

因此指定该字体**零体积**（不捆绑字体文件）。

## 3. 方案

`theme.dart` 的 `fontFamily` 由 `'Microsoft YaHei UI'` 改为 `'Noto Sans SC'`（单行改动）。

- Windows 中文立即用思源黑体，字形+清晰度优于雅黑
- Android 无此字体则回退系统默认（本就清晰）
- 英文数字走思源黑体拉丁字形（风格现代协调）
- 浅/深主题共用同一调用点

## 4. 实现（单文件改动）

**`lib/app/theme.dart`**（当前约 306 行）：

```dart
    fontFamily: 'Noto Sans SC',
```

（注释同步为：Windows 中文用思源黑体（Skia 渲染优于雅黑）。）

## 5. 测试

- widget 测试不依赖字体族，96/96 应保持；`flutter analyze` 0 error。
- 真机验证：重建安装包后中文（任务行/侧边栏/设置页）渲染清晰、字形正常。
- **风险提示**：系统装的是可变字体（VF），Skia 对 VF 兼容性一般但通常可用；
  若真机出现渲染异常/缺字，回退方案 C（保持 YaHei UI）或改方案 B（捆绑思源黑体）。

## 6. 范围外

- 不捆绑字体文件（方案 B 未选）。
- 不改字号/字重体系。
- 不处理 Android。
