# Things 3 化视觉重构设计（v0.2 视觉规范）

日期：2026-11-25
状态：已批准（用户确认设计）
前置：导出备份修复已收官（HEAD `0167feb`，工作区干净）

## 1. 背景与目标

用户多次反馈 UI 难看：当前「质感拟物 + 毛玻璃 + 渐变 + 光斑」风格落地效果不佳
（光斑过淡模糊无内容、玻璃不可感、按钮局促、整体花哨）。经 brainstorming 决策：
**彻底对标 Things 3**——GTD 领域公认的视觉标杆，极简、克制、信息优先。

本 spec 是 v0.2 视觉规范，**取代** v1 规格 §7.4（质感拟物）。

## 2. 决策记录（用户逐项确认）

| 决策点 | 结论 |
|---|---|
| 风格方向 | 对标成熟 GTD 工具（非凭空设计） |
| 对标基准 | Things 3（极简/留白/浅灰层次） |
| 质感拟物元素 | **完全 Things 3 化**：删毛玻璃/渐变/光斑/品牌渐变字 |
| 主色 | Things 蓝 `#3D7CFB`（深色 `#4D8CFF`） |
| 信息架构 | **保留现有 8 项侧边栏/5 项底部导航只换皮**，不改功能 |
| 双主题 | 浅=纯白底、深=纯黑底，跟随系统（沿用） |

## 3. 设计 Token（重写 `AppTokens.light/dark`）

| Token | 浅色 | 深色 | 用途 |
|---|---|---|---|
| `bg` | `#FFFFFF` | `#000000` | Scaffold/页面背景（取代光斑背景） |
| `primary` | `#3D7CFB` | `#4D8CFF` | 主色：选中态/主按钮/完成勾 |
| `text` | `#1A1A1A` | `#F5F5F7` | 主文字 |
| `muted` | `#8A8A8E` | `#8E8E93` | 次级文字/副标题/徽标 |
| `stroke` | `#E5E5EA` | `#2C2C2E` | hairline 分隔线/描边 |
| `fieldBg` | `#F5F5F7` | `#1C1C1E` | 输入框填充 |
| `selectedBg` | `#F2F4FA` | `#1C1C1E` | 侧边栏选中项背景 |
| `danger` | `#FF3B30` | `#FF453A` | 删除/危险操作 |

**删除的 token**：accent/accent2 渐变、ai/ai2 渐变、aiShadow/aiGlow、chipBg/chipText
玻璃底、card/cardSolid 半透明、sidebar/nav 半透明底、shadow 彩色阴影、bg1/bg2 光斑渐变。
（如 theme.dart 中相关字段被其他代码引用，按组件规则替换为 `fieldBg`/`stroke`/`selectedBg`。）

**形状与阴影**：圆角统一 `6`（`radiusCard=8`、`radiusButton=6`、`radiusField=8`）；
全部彩色阴影移除，最多 1px 分隔（无 elevation）。

## 4. 组件规则（Things 3 化）

| 组件 | 规则 |
|---|---|
| Scaffold 背景 | 纯 `bg`；**删除 `SpotBackground`**（文件移除，`GtdApp` builder 不再包裹） |
| AppBar | `bg` 底、`elevation:0`、`surfaceTint:transparent`、标题 `text` 半粗 17、无阴影 |
| 侧边栏/底部导航 | 纯 `bg` + hairline 分隔（侧边栏右侧 1px `stroke`；底部导航顶 1px）；`_Glass` 移除 |
| 侧边栏激活项 | Things 风格：`selectedBg` 圆角背景 + `primary` 图标/文字（非渐变胶囊、非玻璃） |
| 任务行 | 透明行 + 底部 1px `stroke` 分隔；完成态 `muted` + 删除线 |
| 卡片（项目/对话框） | 纯 `bg` + 1px `stroke` 描边 + `radiusCard=8`，0 阴影 |
| 输入框 | `fieldBg` 填充 + 1px `stroke` 描边 + 聚焦 `primary` 描边，`radiusField=8` |
| 主按钮 | 实色 `primary` 底白字，`radiusButton=6`，无光晕（`GradientButton` 改为实色或移除由页面用 `FilledButton`） |
| 完成钮 | `primary` 实心圆勾（未完成：空心描边圆） |
| 状态徽标 | `muted` 小字 + 1px `stroke` 细描边圆角胶囊（无玻璃底） |
| 品牌字 GTD | 普通 `text` 粗体（删 `ShaderMask` 渐变） |
| 收集框 | 白底 + 1px 描边输入框 + `primary` 聚焦边 + 实色圆形 + 按钮（非渐变彩带） |
| 删除确认弹窗 | 保持 `AlertDialog` 结构 + 各 `confirm_*` Key，样式跟随 token（danger 按钮可保留主题默认） |

## 5. 文件改动清单

**核心层（3 个）**：
- `lib/app/theme.dart`：token 重写 + 组件主题（Card/AppBar/Dialog/NavigationBar/Rail/InputDecoration/Button/ListTile/Divider）
- `lib/app/spot_background.dart`：**删除**（引用处同步移除）
- `lib/app/glass.dart`：`GlassContainer`/`GradientButton`/`GlassCheckbox` 改造为 Things 3 化组件（或提供等效替换），保留导出名以减少页面改动（如 `GlassContainer` 改为纯描边容器、`GradientButton` 改为实色按钮、`GlassCheckbox` 改为实心圆勾）——**实现时选择：改造同名组件保持页面 import 不变**，这是最少改动的路径

**外壳与收集（2 个）**：
- `lib/app/responsive_shell.dart`：去 `_Glass`（换纯底+分隔）、去 `_BrandMark` 渐变（换纯文字）
- `lib/features/inbox/quick_collect_bar.dart`、`collect_dialog.dart`：输入框化 + 实色按钮

**页面与对话框（10 个）**：
- `lib/features/inbox/inbox_page.dart`、`today_page.dart`、`waiting_page.dart`、`someday_page.dart`、`projects_page.dart`、`contexts_page.dart`、`review_page.dart`、`settings_page.dart`、`clarify_dialog.dart`、`task_edit_dialog.dart`、`project_dialog.dart`、`task_form_fields.dart`（12 个，行样式/徽标/按钮/卡片替换为 Things 3 风格）

## 6. 测试硬约束

- **全部测试 Key 不动**：`quick_collect_field/button`、`collect_dialog_field/submit`、`task_done_<id>`、`clarify_<id>`、`delete_inbox_<id>`、`new_*_fab`、`*_save`、`confirm_delete_*`、`locale_dropdown`、`export_backup_tile`、`import_backup_tile`、`project_card_<id>` 等。
- **文案不动**：`Pending`/`Clarified`/`@电脑`/`'D:3 N:2 S:1'`/`'AI model config (available in M2)'`/`'Invalid backup file'` 等断言文本保持。
- **结构断言不动**：任务行保持 `ListTile`（含 `title: Text`）、`find.byType(NavigationRail/NavigationBar)` 与 8/5 项计数、`global_collect_fab` 互斥逻辑（第 95 行 `_index != 0 && !const {2, 3, 6}.contains(_index)` 保留）。
- `flutter test` 96/96 全绿；`flutter analyze` 0 error。
- l10n ARB 不得改动。

## 7. 验证

1. 全量 `flutter test` 96/96、analyze 0 error。
2. 重建安装包 → 截图（浅色 + 深色）→ 用户确认 Things 3 化达标。
3. 人工走查：断点两套布局、快速收集、理清五路径、四视图、回顾、设置语言/导出/恢复。

## 8. 范围外（明确不做）

- 不改信息架构（8 项/5 项不变）
- 不改任何业务逻辑/数据层
- 不引入新功能
- 不改窗口标题/图标
- 不重做 ARB 文案
