# 安顿 Settle「桌面设置增强」实施计划（可配置快捷键 + 窗口置顶 + 平台能力分离）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-subagent-driven-development (recommended) or superpowers-executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为安顿 Settle 引入「桌面设置增强」三项能力：① **可配置快捷键**——把现有硬编码的 16 个应用内快捷键（壳层 N 收集 / Ctrl/Cmd+1..9 侧边栏 / Ctrl/Cmd+0 回顾 / 列表层 J/K/Enter/Delete）迁移到一张 16 动作规范表 + 用户可改绑的配置（`lib/core/shortcuts/` 新模块 + 设置页快捷键配置子页 + 录键弹窗），默认绑定与现状逐键一致、零行为回归；② **窗口置顶（always-on-top）**——基于新依赖 window_manager，设置页开关与 `Ctrl+Shift+T` 快捷键双通道实时置顶，启动时恢复上次置顶状态；③ **平台能力分离架构**——新增 `lib/core/platform/` 模块（PlatformBridge 门面 + WindowService 接口/桌面实现/no-op 实现 + Riverpod provider 注入），把现有 3 处内联平台判定收口，业务代码零平台判定。

**Architecture:** 平台能力收口于 `lib/core/platform/`（PlatformBridge 读 defaultTargetPlatform + kIsWeb；WindowService 接口 + NoopWindowService + createWindowService 工厂 + provider；DesktopWindowService 是**全仓唯一 import window_manager 的文件**，内部含平台守卫）；快捷键领域层 `lib/core/shortcuts/`（16 动作规范表 + ShortcutBinding 模型 + ShortcutSettingsController ChangeNotifier）；置顶唯一状态源 `lib/app/window_controller.dart`（WindowController.toggle() 唯一写点，设置开关与快捷键双通道汇合；`main()` 启动 ensureInitialized + restoreAlwaysOnTop）；设置 UI `lib/features/settings/shortcuts/`（配置页 + 录键弹窗 + 动作名集中解析）。持久化仅 2 个纯新增 SharedPreferences key（`shortcut_bindings` / `always_on_top`），无数据迁移。

**Tech Stack:** Flutter/Dart、drift、shared_preferences（沿用既有读写模式）、flutter_riverpod（ChangeNotifierProvider/Provider 注入）、**新依赖 window_manager `^0.5.2`**（经典 API；0.6+ 起经典 API 移入 legacy.dart 并标记 deprecated，会产生 analyze 告警，故锁定 0.5.x）、flutter gen-l10n。

**Spec:** `docs/superpowers/specs/2026-11-27-desktop-settings-design.md`

**基线（已确认）：** 分支 `milestone-1`，HEAD `5ee50d2`，工作区干净，测试 217/217 全绿，analyze 0 error（3 warning / 69 info 基线，新增代码须 0 warning）。Flutter 3.50.1 stable（本机 C:\flutter），Dart ^3.14.0。window_manager 0.5.2 的 pub 约束为 `sdk >=3.0.0 <4.0.0 / flutter >=3.3.0`，与本机 SDK 兼容（已对 pub.dev 核实；pubspec.lock 在库内，需一并提交）。

**环境约定（每步命令沿用）：**
- 所有 flutter 命令前先设置 `$env:PATH = "C:\flutter\bin;$env:PATH"`。
- 提交一律新提交，**不使用 --amend**；commit message 用**单引号**包裹（消息均为中文 + 全角标点，无内嵌单引号/双引号，PowerShell 单引号原样传递；本仓库改名/指南计划已实证该方式提交中文消息正常）。若某条消息需含特殊字符导致编码异常，改用消息文件：`Set-Content -Path "$env:TEMP\commit-msg.txt" -Value $msg -Encoding UTF8` 后 `git commit -F "$env:TEMP\commit-msg.txt"`。
- grep 审计命令无匹配时退出码为 1，属预期（git grep 行为），不以报错论。
- `flutter test`/`flutter analyze` 输出追加 `2>&1 | Select-Object -Last 1`（test）或 `-Last 3`（analyze）只看汇总行。
- 每个 Task 结束前必须 `flutter analyze` **0 error 且新增代码 0 warning** + `flutter test` 全绿，才允许提交。

**关键依赖说明（跨 Task）：**
- **Task 1（l10n 32 key）是 Task 3/4/5/6 的编译前置**：新 key（action* / shortcuts* / capture* / key* / settings*）缺失则各页面/组件编译不过；`captureConflict` 含 `{action}` 占位符，arb 必须声明 `@captureConflict` placeholders（沿用 `reminderBannerTitle` 同款模式），生成 `String captureConflict(String action)`。
- **Task 2（platform 模块 + window_manager 依赖）必须先落地并过 analyze/测试**：Task 6 的壳层/列表层接线与 Task 5 的窗口控制都依赖 PlatformBridge/WindowService/provider；window_manager 依赖加入后，本 Task 内即完成 analyze + 测试（全仓 0 error）再继续。
- **Task 3（shortcuts 领域层）是 Task 4/6 的前置**：配置页/录键弹窗/接线全部依赖 16 动作表 + 控制器。
- **Task 4（配置 UI）是 Task 5 的前置**：设置页快捷键 tile 的 `Navigator.push` 目标 ShortcutSettingsPage 必须先存在。
- **Task 5（窗口置顶）在 Task 4 之后**：settings_page 的置顶开关 tile 引用 `windowControllerProvider`（Task 5 新建），两 tile 同一步插入 settings_page——故设置页双 tile 的全部改动（含 settings_page_test 扩展）集中在 Task 5。
- **Task 6（双层接线）最后做**：壳层与列表层改表后，`responsive_shell_test.dart` 与 `task_list_view_test.dart` **不改一行**原样通过 = 默认绑定逐键还原现状的回归证明（门禁）。
- **Task 7（情境视图，spec 增补 commit 5ee50d2）在 Task 6 之后**：依赖 Task 1（l10n 机制与既有 key）+ Task 2（PlatformBridge.isDesktop 供 focusEnabled）；数据层零改动（`watchByContext` 已就绪）；`contextTasksEmpty` 在 Task 7 内追加（Task 1 定稿 32 key 及其 arb diff/计数/提交消息全部不动）；原 Task 7（收官验证）顺延为 **Task 8**。
- **`flutter build windows --release` 硬门禁**：window_manager 首次引入原生插件，Task 5 内首跑，Task 8 收官复跑。
- 测试惯例：文件级私有 StreamProvider、testWidgets 末尾 `await env.db.close()`、桌面场景 `useDesktop()`（`debugDefaultTargetPlatformOverride = TargetPlatform.windows`）与 `sendCtrlKey` 完整 down/up 序列（见既有测试同款实现）。

**16 动作默认绑定契约（spec 功能一 §1，逐键还原现状；注册展开列 = 实际注册键集）：**

| id | labelKey | layer | navSpecIndex | 默认绑定（存储形） | 注册展开 |
|---|---|---|---|---|---|
| `collect` | actionCollect | shell | – | KeyN（无修饰） | N |
| `navInbox` | actionNavInbox | shell | 0 | Digit1 + control | Ctrl+1, Cmd+1 |
| `navToday` | actionNavToday | shell | 1 | Digit2 + control | Ctrl+2, Cmd+2 |
| `navUpcoming` | actionNavUpcoming | shell | 2 | Digit3 + control | Ctrl+3, Cmd+3 |
| `navAnytime` | actionNavAnytime | shell | 3 | Digit4 + control | Ctrl+4, Cmd+4 |
| `navSomeday` | actionNavSomeday | shell | 4 | Digit5 + control | Ctrl+5, Cmd+5 |
| `navProjects` | actionNavProjects | shell | 5 | Digit6 + control | Ctrl+6, Cmd+6 |
| `navContexts` | actionNavContexts | shell | 6 | Digit7 + control | Ctrl+7, Cmd+7 |
| `navWaiting` | actionNavWaiting | shell | 7 | Digit8 + control | Ctrl+8, Cmd+8 |
| `navLogbook` | actionNavLogbook | shell | 8 | Digit9 + control | Ctrl+9, Cmd+9 |
| `navReview` | actionNavReview | shell | 9 | Digit0 + control | Ctrl+0, Cmd+0 |
| `listMoveUp` | actionListUp | list | – | KeyJ（无修饰） | J |
| `listMoveDown` | actionListDown | list | – | KeyK（无修饰） | K |
| `listComplete` | actionListComplete | list | – | Enter（无修饰） | Enter |
| `listDelete` | actionListDelete | list | – | Delete（无修饰） | Delete |
| `toggleAlwaysOnTop` | actionToggleAlwaysOnTop | shell | – | KeyT + control + shift | Ctrl+Shift+T, Cmd+Shift+T |

> 键名序列化使用键名协议字符串（'KeyN'/'Digit2'/'Enter'/'Delete'，自定协议——本 SDK 无 `LogicalKeyboardKey.keyName` 字段）；键帽显示标签用 `LogicalKeyboardKey.keyLabel`（本 SDK 有该字段，release 可用）。

---

### Task 1: l10n 新增 32 key（设置页/配置页/动作名/录键/键帽）+ gen-l10n 再生成 + 双语冒烟扩展

**Files:**
- Modify: `lib/i18n/l10n/app_en.arb`（末尾追加 32 key + `@captureConflict` 元数据）
- Modify: `lib/i18n/l10n/app_zh.arb`（末尾追加 32 key + `@captureConflict` 元数据）
- Regenerate: `lib/i18n/l10n/app_localizations.dart` / `app_localizations_en.dart` / `app_localizations_zh.dart`（`flutter gen-l10n`，不改手写）
- Test: `test/widget/l10n_smoke_test.dart`（新增桌面设置 keys 双语冒烟）

- [x] **Step 1: 先写双语冒烟测试（红）**

在 `test/widget/l10n_smoke_test.dart` 末尾 `}`（文件最后一行，main 收尾）之前追加：

```dart
  testWidgets('desktop settings keys load in zh and en', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(
            '${l10n.settingsShortcuts}|${l10n.settingsAlwaysOnTop}|${l10n.actionCollect}|${l10n.actionToggleAlwaysOnTop}|${l10n.capturePrompt}|${l10n.captureConflict('收件箱')}|${l10n.keyCtrl}');
      }),
    ));
    expect(
      find.text('快捷键|窗口置顶|收集|切换窗口置顶|按下新快捷键…|该快捷键已被 收件箱 占用|Ctrl'),
      findsOneWidget,
    );
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return Text(
            '${l10n.settingsShortcuts}|${l10n.settingsAlwaysOnTop}|${l10n.actionCollect}|${l10n.actionToggleAlwaysOnTop}|${l10n.capturePrompt}|${l10n.captureConflict('Inbox')}|${l10n.keyCtrl}');
      }),
    ));
    expect(
      find.text('Keyboard Shortcuts|Always on Top|Collect|Toggle Always on Top|Press new shortcut…|This shortcut is already used by Inbox|Ctrl'),
      findsOneWidget,
    );
  });
```

（注：`captureConflict` 生成签名 `String captureConflict(String action)`——zh 文案「该快捷键已被 收件箱 占用」中 `{action}` 被替换为「收件箱」，与占位符声明一致。）

- [x] **Step 2: 运行冒烟测试确认失败**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test test/widget/l10n_smoke_test.dart 2>&1 | Select-Object -Last 3
```

Expected: 编译失败（`settingsShortcuts` getter 不存在 / `desktop settings keys load in zh and en` 用例报错）——证明测试先行。

- [x] **Step 3: `app_en.arb` 末尾追加 32 key（含 captureConflict 占位符声明）**

改前（文件末尾两行 + 收尾 `}`）：

```json
  "guideNote4": "Export a JSON backup anytime."
}
```

改后：

```json
  "guideNote4": "Export a JSON backup anytime.",
  "settingsShortcuts": "Keyboard Shortcuts",
  "settingsAlwaysOnTop": "Always on Top",
  "settingsAlwaysOnTopHint": "Keep the window above others",
  "shortcutsTitle": "Keyboard Shortcuts",
  "shortcutsGroupGlobal": "Global",
  "shortcutsGroupList": "Lists",
  "shortcutsReset": "Reset to Defaults",
  "shortcutsResetConfirm": "Reset all shortcuts to their defaults?",
  "actionCollect": "Collect",
  "actionNavInbox": "Inbox",
  "actionNavToday": "Today",
  "actionNavUpcoming": "Upcoming",
  "actionNavAnytime": "Anytime",
  "actionNavSomeday": "Someday",
  "actionNavProjects": "Projects",
  "actionNavContexts": "Contexts",
  "actionNavWaiting": "Waiting",
  "actionNavLogbook": "Logbook",
  "actionNavReview": "Review",
  "actionListUp": "Focus Up",
  "actionListDown": "Focus Down",
  "actionListComplete": "Complete Focused Task",
  "actionListDelete": "Delete Focused Task",
  "actionToggleAlwaysOnTop": "Toggle Always on Top",
  "capturePrompt": "Press new shortcut…",
  "captureEscHint": "Press Esc to cancel",
  "captureConflict": "This shortcut is already used by {action}",
  "@captureConflict": {
    "description": "Conflict message shown when a captured shortcut is already bound to another action.",
    "placeholders": {
      "action": {
        "type": "String",
        "example": "Inbox"
      }
    }
  },
  "captureModifiersOnlyHint": "Include at least one non-modifier key",
  "keyCtrl": "Ctrl",
  "keyCmd": "Cmd",
  "keyShift": "Shift",
  "keyAlt": "Alt"
}
```

- [x] **Step 4: `app_zh.arb` 末尾追加 32 key（含 captureConflict 占位符声明）**

改前（文件末尾两行 + 收尾 `}`）：

```json
  "guideNote4": "数据可以随时导出 JSON 备份。"
}
```

改后：

```json
  "guideNote4": "数据可以随时导出 JSON 备份。",
  "settingsShortcuts": "快捷键",
  "settingsAlwaysOnTop": "窗口置顶",
  "settingsAlwaysOnTopHint": "固定到桌面最前置",
  "shortcutsTitle": "快捷键",
  "shortcutsGroupGlobal": "全局",
  "shortcutsGroupList": "列表",
  "shortcutsReset": "恢复默认",
  "shortcutsResetConfirm": "确定恢复所有快捷键为默认设置？",
  "actionCollect": "收集",
  "actionNavInbox": "收件箱",
  "actionNavToday": "今日",
  "actionNavUpcoming": "即将",
  "actionNavAnytime": "随时",
  "actionNavSomeday": "将来也许",
  "actionNavProjects": "项目",
  "actionNavContexts": "情境",
  "actionNavWaiting": "等待",
  "actionNavLogbook": "日志",
  "actionNavReview": "回顾",
  "actionListUp": "焦点上移",
  "actionListDown": "焦点下移",
  "actionListComplete": "完成焦点任务",
  "actionListDelete": "删除焦点任务",
  "actionToggleAlwaysOnTop": "切换窗口置顶",
  "capturePrompt": "按下新快捷键…",
  "captureEscHint": "按 Esc 取消",
  "captureConflict": "该快捷键已被 {action} 占用",
  "@captureConflict": {
    "description": "录键冲突提示：该快捷键已被另一动作占用。",
    "placeholders": {
      "action": {
        "type": "String",
        "example": "收件箱"
      }
    }
  },
  "captureModifiersOnlyHint": "请至少包含一个非修饰键",
  "keyCtrl": "Ctrl",
  "keyCmd": "Cmd",
  "keyShift": "Shift",
  "keyAlt": "Alt"
}
```

（zh/en 的键帽四 key 均为「Ctrl/Cmd/Shift/Alt」拉丁原词，spec 文案表如此。）

- [x] **Step 5: 重新生成 l10n 并确认 3 个 dart 文件更新**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter gen-l10n
git status --short lib/i18n/l10n
```

Expected: `flutter gen-l10n` 退出码 0；`git status --short` 显示 `app_localizations.dart` / `app_localizations_en.dart` / `app_localizations_zh.dart` 三个文件被修改（还有两个 arb 文件）。

- [x] **Step 6: 冒烟测试通过（绿）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter test test/widget/l10n_smoke_test.dart 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`。

- [x] **Step 7: analyze 门禁**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
flutter analyze 2>&1 | Select-Object -Last 3
```

Expected: 汇总行 0 error 且 0 warning（仅既有 3 warning / 69 info 基线不动）。

- [x] **Step 8: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/i18n/l10n/app_en.arb lib/i18n/l10n/app_zh.arb lib/i18n/l10n/app_localizations.dart lib/i18n/l10n/app_localizations_en.dart lib/i18n/l10n/app_localizations_zh.dart test/widget/l10n_smoke_test.dart
git commit -m 'feat(l10n): 桌面设置增强 32 个新 key（设置/动作名/录键/键帽）+ 双语冒烟扩展'
```

Expected: 提交成功；`git status --short` 无新增修改。
### Task 2: 平台能力收口模块（PlatformBridge + WindowService）+ window_manager 依赖

**Files:**
- Modify: `pubspec.yaml`（新增 `window_manager: ^0.5.2`）+ `pubspec.lock`（pub get 更新）
- Create: `lib/core/platform/platform_bridge.dart` / `window_service.dart` / `window_service_desktop.dart`

- [x] **Step 1: pubspec.yaml 新增 window_manager**

改前：

```yaml
  file_picker: ^8.1.2

dev_dependencies:
```

改后：

```yaml
  file_picker: ^8.1.2
  window_manager: ^0.5.2

dev_dependencies:
```

- [x] **Step 2: pub get 解析依赖**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter pub get
```

Expected: `Got dependencies!`，输出含 `+ window_manager 0.5.2`。若 pub 解析失败（网络/版本不可达），停在本步报告，不继续。

- [x] **Step 3: 新建 `lib/core/platform/platform_bridge.dart`（完整文件）**

```dart
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 平台能力门面：feature/业务代码唯一允许的平台判定入口。
/// 读 defaultTargetPlatform + kIsWeb；经 Riverpod provider 注入，测试可 override。
/// 收敛对象（桌面设置 spec）：responsive_shell `_shortcutsEnabled` 与
/// task_list_view 快捷键门禁的 3 处内联判定，全部改经本门面读取。
class PlatformBridge {
  const PlatformBridge({required this.isDesktop, required this.isMacOS});

  /// 桌面（Windows/macOS/Linux，含 Web）：快捷键/置顶等桌面能力门控。
  final bool isDesktop;

  /// macOS：键帽「Ctrl/Cmd 平台自适应」展示判定。
  final bool isMacOS;

  factory PlatformBridge.detect() {
    final p = defaultTargetPlatform;
    return PlatformBridge(
      isDesktop: kIsWeb ||
          p == TargetPlatform.windows ||
          p == TargetPlatform.macOS ||
          p == TargetPlatform.linux,
      isMacOS: p == TargetPlatform.macOS,
    );
  }
}

final platformBridgeProvider =
    Provider<PlatformBridge>((ref) => PlatformBridge.detect());
```

- [x] **Step 4: 新建 `lib/core/platform/window_service.dart`（完整文件）**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'platform_bridge.dart';
import 'window_service_desktop.dart';

/// 窗口能力服务：feature 层只依赖此接口，永不直接接触平台插件。
/// 本轮能力仅置顶（setAlwaysOnTop）；未来托盘/系统通知/全局热键各成
/// service 收进 lib/core/platform/。
abstract class WindowService {
  Future<void> ensureInitialized();
  Future<void> setAlwaysOnTop(bool value);
}

/// no-op 空实现：移动端（非桌面）默认注入，置顶自动不可用。
class NoopWindowService implements WindowService {
  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> setAlwaysOnTop(bool value) async {}
}

/// 唯一实现选择点：main() 与 provider 共用，避免选择逻辑双份。
/// 桌面 → DesktopWindowService；移动 → NoopWindowService（实现内运行时守卫再兜一层）。
WindowService createWindowService({required bool isDesktop}) =>
    isDesktop ? DesktopWindowService() : NoopWindowService();

final windowServiceProvider = Provider<WindowService>(
  (ref) => createWindowService(
    isDesktop: ref.watch(platformBridgeProvider).isDesktop,
  ),
);
```

- [x] **Step 5: 新建 `lib/core/platform/window_service_desktop.dart`（完整文件，全仓唯一 import window_manager 的文件）**

```dart
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:window_manager/window_manager.dart';
import 'window_service.dart';

/// 窗口能力桌面实现：**全仓唯一 import window_manager 的文件**。
/// 内部 `_isSupported` 运行时守卫：非桌面平台（provider 已选 no-op 的兜底
/// 路径）与测试环境（debugDefaultTargetPlatformOverride 非桌面）绝不触
/// 真实插件——避免 MissingPluginException。
class DesktopWindowService implements WindowService {
  static bool get _isSupported =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  @override
  Future<void> ensureInitialized() async {
    if (_isSupported) await windowManager.ensureInitialized();
  }

  @override
  Future<void> setAlwaysOnTop(bool value) async {
    if (_isSupported) await windowManager.setAlwaysOnTop(value);
  }
}
```

- [x] **Step 6: analyze + 全量测试门禁（window_manager 依赖加入后必须先全绿再继续）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter analyze 2>&1 | Select-Object -Last 3
flutter test 2>&1 | Select-Object -Last 1
```

Expected: analyze 汇总行 0 error 且 0 warning；`flutter test` → `All tests passed!`（217 基线不动，本 Task 无新增测试）。

- [x] **Step 7: 提交**

```powershell
cd D:\Project\gtd-project
git add pubspec.yaml pubspec.lock lib/core/platform
git commit -m 'feat(platform): 平台能力收口——PlatformBridge + WindowService 接口/桌面实现/no-op + window_manager 依赖'
```

Expected: 提交成功。
### Task 3: 快捷键领域层（16 动作规范表 + ShortcutBinding + 设置控制器）+ 单元测试

**Files:**
- Create: `lib/core/shortcuts/shortcut_bindings.dart` / `shortcut_actions.dart` / `shortcut_settings_controller.dart`
- Create: `test/core/shortcut_settings_controller_test.dart`（新建 `test/core/` 目录）

- [x] **Step 1: 新建 `lib/core/shortcuts/shortcut_bindings.dart`（完整文件）**

```dart
import 'package:flutter/services.dart' show LogicalKeyboardKey;

/// 单动作快捷键绑定（存储形）：key 为键名协议字符串（自定协议，非 SDK API——
/// 本 SDK 无 `LogicalKeyboardKey.keyName` 字段），如 'KeyN'、'Digit2'、
/// 'Enter'、'Delete'，跨平台稳定且可经 [_keysByName] 还原。
/// 修饰符 bool 仅序列化 true 项。
class ShortcutBinding {
  const ShortcutBinding({
    required this.key,
    this.control = false,
    this.meta = false,
    this.shift = false,
    this.alt = false,
  });

  final String key;
  final bool control;
  final bool meta;
  final bool shift;
  final bool alt;

  /// 规范化标识（键 + 全部修饰符）：冲突判定与等值比较基础。
  String get normalizedId =>
      '$key|${control ? 1 : 0}|${meta ? 1 : 0}|${shift ? 1 : 0}|${alt ? 1 : 0}';

  /// control↔meta 互换变体（派生注册用：macOS Cmd / Windows Ctrl 双注册）。
  ShortcutBinding swapControlMeta() => ShortcutBinding(
        key: key,
        control: meta,
        meta: control,
        shift: shift,
        alt: alt,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        if (control) 'control': true,
        if (meta) 'meta': true,
        if (shift) 'shift': true,
        if (alt) 'alt': true,
      };

  /// 解码：修饰符缺省 false；key 缺失/非字符串/未知键名抛 FormatException
  /// （调用方防御性捕获后忽略该项，回退默认绑定）。
  factory ShortcutBinding.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String || key.isEmpty) {
      throw const FormatException('shortcut_bindings 条目缺少 key');
    }
    if (!_keysByName.containsKey(key)) {
      throw FormatException('未知快捷键键名: $key');
    }
    return ShortcutBinding(
      key: key,
      control: json['control'] == true,
      meta: json['meta'] == true,
      shift: json['shift'] == true,
      alt: json['alt'] == true,
    );
  }
}

/// 键名协议 → LogicalKeyboardKey（覆盖默认绑定全部键 + 常用重绑目标；
/// 未知键名 fromJson 抛 FormatException，防御忽略回默认）。
LogicalKeyboardKey? logicalKeyForKeyName(String keyName) =>
    _keysByName[keyName];

/// 反查：LogicalKeyboardKey → 键名协议字符串（录键弹窗用；
/// 修饰键/媒体键等不可序列化键抛 FormatException，调用方防御处理）。
String keyNameOf(LogicalKeyboardKey key) => _keysByName.entries
    .firstWhere(
      (e) => e.value == key,
      orElse: () => throw FormatException('不可捕获的键: $key'),
    )
    .key;

const Map<String, LogicalKeyboardKey> _keysByName = {
  // 字母 A..Z
  'KeyA': LogicalKeyboardKey.keyA,
  'KeyB': LogicalKeyboardKey.keyB,
  'KeyC': LogicalKeyboardKey.keyC,
  'KeyD': LogicalKeyboardKey.keyD,
  'KeyE': LogicalKeyboardKey.keyE,
  'KeyF': LogicalKeyboardKey.keyF,
  'KeyG': LogicalKeyboardKey.keyG,
  'KeyH': LogicalKeyboardKey.keyH,
  'KeyI': LogicalKeyboardKey.keyI,
  'KeyJ': LogicalKeyboardKey.keyJ,
  'KeyK': LogicalKeyboardKey.keyK,
  'KeyL': LogicalKeyboardKey.keyL,
  'KeyM': LogicalKeyboardKey.keyM,
  'KeyN': LogicalKeyboardKey.keyN,
  'KeyO': LogicalKeyboardKey.keyO,
  'KeyP': LogicalKeyboardKey.keyP,
  'KeyQ': LogicalKeyboardKey.keyQ,
  'KeyR': LogicalKeyboardKey.keyR,
  'KeyS': LogicalKeyboardKey.keyS,
  'KeyT': LogicalKeyboardKey.keyT,
  'KeyU': LogicalKeyboardKey.keyU,
  'KeyV': LogicalKeyboardKey.keyV,
  'KeyW': LogicalKeyboardKey.keyW,
  'KeyX': LogicalKeyboardKey.keyX,
  'KeyY': LogicalKeyboardKey.keyY,
  'KeyZ': LogicalKeyboardKey.keyZ,
  // 数字 0..9
  'Digit0': LogicalKeyboardKey.digit0,
  'Digit1': LogicalKeyboardKey.digit1,
  'Digit2': LogicalKeyboardKey.digit2,
  'Digit3': LogicalKeyboardKey.digit3,
  'Digit4': LogicalKeyboardKey.digit4,
  'Digit5': LogicalKeyboardKey.digit5,
  'Digit6': LogicalKeyboardKey.digit6,
  'Digit7': LogicalKeyboardKey.digit7,
  'Digit8': LogicalKeyboardKey.digit8,
  'Digit9': LogicalKeyboardKey.digit9,
  // 功能键 F1..F12
  'F1': LogicalKeyboardKey.f1,
  'F2': LogicalKeyboardKey.f2,
  'F3': LogicalKeyboardKey.f3,
  'F4': LogicalKeyboardKey.f4,
  'F5': LogicalKeyboardKey.f5,
  'F6': LogicalKeyboardKey.f6,
  'F7': LogicalKeyboardKey.f7,
  'F8': LogicalKeyboardKey.f8,
  'F9': LogicalKeyboardKey.f9,
  'F10': LogicalKeyboardKey.f10,
  'F11': LogicalKeyboardKey.f11,
  'F12': LogicalKeyboardKey.f12,
  // 小键盘
  'Numpad0': LogicalKeyboardKey.numpad0,
  'Numpad1': LogicalKeyboardKey.numpad1,
  'Numpad2': LogicalKeyboardKey.numpad2,
  'Numpad3': LogicalKeyboardKey.numpad3,
  'Numpad4': LogicalKeyboardKey.numpad4,
  'Numpad5': LogicalKeyboardKey.numpad5,
  'Numpad6': LogicalKeyboardKey.numpad6,
  'Numpad7': LogicalKeyboardKey.numpad7,
  'Numpad8': LogicalKeyboardKey.numpad8,
  'Numpad9': LogicalKeyboardKey.numpad9,
  'NumpadEnter': LogicalKeyboardKey.numpadEnter,
  'NumpadAdd': LogicalKeyboardKey.numpadAdd,
  'NumpadSubtract': LogicalKeyboardKey.numpadSubtract,
  'NumpadMultiply': LogicalKeyboardKey.numpadMultiply,
  'NumpadDivide': LogicalKeyboardKey.numpadDivide,
  'NumpadDecimal': LogicalKeyboardKey.numpadDecimal,
  // 标点
  'Period': LogicalKeyboardKey.period,
  'Comma': LogicalKeyboardKey.comma,
  'Slash': LogicalKeyboardKey.slash,
  'Backslash': LogicalKeyboardKey.backslash,
  'Semicolon': LogicalKeyboardKey.semicolon,
  'Quote': LogicalKeyboardKey.quote,
  'BracketLeft': LogicalKeyboardKey.bracketLeft,
  'BracketRight': LogicalKeyboardKey.bracketRight,
  'Minus': LogicalKeyboardKey.minus,
  'Equal': LogicalKeyboardKey.equal,
  'Backquote': LogicalKeyboardKey.backquote,
  // 导航
  'ArrowUp': LogicalKeyboardKey.arrowUp,
  'ArrowDown': LogicalKeyboardKey.arrowDown,
  'ArrowLeft': LogicalKeyboardKey.arrowLeft,
  'ArrowRight': LogicalKeyboardKey.arrowRight,
  'Home': LogicalKeyboardKey.home,
  'End': LogicalKeyboardKey.end,
  'PageUp': LogicalKeyboardKey.pageUp,
  'PageDown': LogicalKeyboardKey.pageDown,
  // 编辑键
  'Enter': LogicalKeyboardKey.enter,
  'Delete': LogicalKeyboardKey.delete,
  'Space': LogicalKeyboardKey.space,
  'Tab': LogicalKeyboardKey.tab,
  'Backspace': LogicalKeyboardKey.backspace,
  'Insert': LogicalKeyboardKey.insert,
  // 锁定/系统键
  'CapsLock': LogicalKeyboardKey.capsLock,
  'NumLock': LogicalKeyboardKey.numLock,
  'ScrollLock': LogicalKeyboardKey.scrollLock,
  'Pause': LogicalKeyboardKey.pause,
  'PrintScreen': LogicalKeyboardKey.printScreen,
  'Escape': LogicalKeyboardKey.escape,
};
```

（键名 const 已对本机 SDK `keyboard_key.g.dart` 逐名核实：enter/delete/space/tab/backspace/escape/arrow*/home/end/pageUp/pageDown/insert/printScreen/capsLock/numLock/scrollLock/pause/period/comma/slash/backslash/semicolon/quote/bracketLeft/bracketRight/minus/equal/backquote/f1/numpadEnter/numpadAdd/numpadSubtract/numpadMultiply/numpadDivide/numpadDecimal/keyA/digit0 全部存在；KeyB..KeyZ / Digit1..9 / F2..12 / Numpad0..9 为同一命名序列。）

- [x] **Step 2: 新建 `lib/core/shortcuts/shortcut_actions.dart`（完整文件）**

```dart
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, ShortcutActivator, SingleActivator;
import 'shortcut_bindings.dart';

/// 快捷键作用层：shell = 壳层全局组；list = 列表层（列表组）。UI 分组复用。
enum ShortcutLayer { shell, list }

/// 16 动作规范表条目：默认绑定与现状逐键一致（spec 功能一 §1 表格即契约）。
class ShortcutAction {
  const ShortcutAction({
    required this.id,
    required this.labelKey,
    required this.layer,
    required this.defaultBinding,
    this.navSpecIndex,
  });

  final String id;

  /// l10n key（actionCollect / actionNav* / ...），经 shortcut_labels 解析。
  final String labelKey;

  final ShortcutLayer layer;
  final ShortcutBinding defaultBinding;

  /// 仅 nav* 动作：_navSpecs 中的位置（0..9），构建期解析 `.index`。
  final int? navSpecIndex;
}

/// 16 动作规范表（唯一事实源）：UI 行序 = 本表序。
/// 默认绑定逐键还原现状：N / Ctrl/Cmd+1..9 / Ctrl/Cmd+0 / J / K / Enter / Delete；
/// 新增 toggleAlwaysOnTop = Ctrl+Shift+T（spec 功能二）。
const List<ShortcutAction> shortcutActions = [
  ShortcutAction(
    id: 'collect',
    labelKey: 'actionCollect',
    layer: ShortcutLayer.shell,
    defaultBinding: ShortcutBinding(key: 'KeyN'),
  ),
  ShortcutAction(
    id: 'navInbox',
    labelKey: 'actionNavInbox',
    layer: ShortcutLayer.shell,
    navSpecIndex: 0,
    defaultBinding: ShortcutBinding(key: 'Digit1', control: true),
  ),
  ShortcutAction(
    id: 'navToday',
    labelKey: 'actionNavToday',
    layer: ShortcutLayer.shell,
    navSpecIndex: 1,
    defaultBinding: ShortcutBinding(key: 'Digit2', control: true),
  ),
  ShortcutAction(
    id: 'navUpcoming',
    labelKey: 'actionNavUpcoming',
    layer: ShortcutLayer.shell,
    navSpecIndex: 2,
    defaultBinding: ShortcutBinding(key: 'Digit3', control: true),
  ),
  ShortcutAction(
    id: 'navAnytime',
    labelKey: 'actionNavAnytime',
    layer: ShortcutLayer.shell,
    navSpecIndex: 3,
    defaultBinding: ShortcutBinding(key: 'Digit4', control: true),
  ),
  ShortcutAction(
    id: 'navSomeday',
    labelKey: 'actionNavSomeday',
    layer: ShortcutLayer.shell,
    navSpecIndex: 4,
    defaultBinding: ShortcutBinding(key: 'Digit5', control: true),
  ),
  ShortcutAction(
    id: 'navProjects',
    labelKey: 'actionNavProjects',
    layer: ShortcutLayer.shell,
    navSpecIndex: 5,
    defaultBinding: ShortcutBinding(key: 'Digit6', control: true),
  ),
  ShortcutAction(
    id: 'navContexts',
    labelKey: 'actionNavContexts',
    layer: ShortcutLayer.shell,
    navSpecIndex: 6,
    defaultBinding: ShortcutBinding(key: 'Digit7', control: true),
  ),
  ShortcutAction(
    id: 'navWaiting',
    labelKey: 'actionNavWaiting',
    layer: ShortcutLayer.shell,
    navSpecIndex: 7,
    defaultBinding: ShortcutBinding(key: 'Digit8', control: true),
  ),
  ShortcutAction(
    id: 'navLogbook',
    labelKey: 'actionNavLogbook',
    layer: ShortcutLayer.shell,
    navSpecIndex: 8,
    defaultBinding: ShortcutBinding(key: 'Digit9', control: true),
  ),
  ShortcutAction(
    id: 'navReview',
    labelKey: 'actionNavReview',
    layer: ShortcutLayer.shell,
    navSpecIndex: 9,
    defaultBinding: ShortcutBinding(key: 'Digit0', control: true),
  ),
  ShortcutAction(
    id: 'listMoveUp',
    labelKey: 'actionListUp',
    layer: ShortcutLayer.list,
    defaultBinding: ShortcutBinding(key: 'KeyJ'),
  ),
  ShortcutAction(
    id: 'listMoveDown',
    labelKey: 'actionListDown',
    layer: ShortcutLayer.list,
    defaultBinding: ShortcutBinding(key: 'KeyK'),
  ),
  ShortcutAction(
    id: 'listComplete',
    labelKey: 'actionListComplete',
    layer: ShortcutLayer.list,
    defaultBinding: ShortcutBinding(key: 'Enter'),
  ),
  ShortcutAction(
    id: 'listDelete',
    labelKey: 'actionListDelete',
    layer: ShortcutLayer.list,
    defaultBinding: ShortcutBinding(key: 'Delete'),
  ),
  ShortcutAction(
    id: 'toggleAlwaysOnTop',
    labelKey: 'actionToggleAlwaysOnTop',
    layer: ShortcutLayer.shell,
    defaultBinding: ShortcutBinding(key: 'KeyT', control: true, shift: true),
  ),
];

/// 按 id 查动作：防御加载期未知 actionId 条目与非法引用。
ShortcutAction actionById(String id) => shortcutActions.firstWhere(
      (a) => a.id == id,
      orElse: () => throw ArgumentError('未知快捷键动作: $id'),
    );

/// 注册展开：绑定本身 + 当且仅当 control != meta 时附 swapControlMeta 派生
/// 变体（保持现状 Ctrl/Cmd 双注册语义：collect=N 不派生；nav*=Ctrl+n 派生
/// Cmd+n；toggle=Ctrl+Shift+T 派生 Cmd+Shift+T；control&&meta 双真不派生）。
List<ShortcutActivator> activatorsFor(ShortcutBinding binding) {
  final key = logicalKeyForKeyName(binding.key);
  if (key == null) {
    throw StateError('非法快捷键键名: ${binding.key}');
  }
  final primary = SingleActivator(
    key,
    control: binding.control,
    meta: binding.meta,
    shift: binding.shift,
    alt: binding.alt,
  );
  if (binding.control == binding.meta) return [primary];
  final swapped = SingleActivator(
    key,
    control: binding.meta,
    meta: binding.control,
    shift: binding.shift,
    alt: binding.alt,
  );
  return [primary, swapped];
}
```

- [x] **Step 3: 新建 `lib/core/shortcuts/shortcut_settings_controller.dart`（完整文件）**

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/services.dart'
    show ShortcutActivator, SingleActivator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shortcut_actions.dart';
import 'shortcut_bindings.dart';

/// 快捷键设置控制器：持久化到 SharedPreferences 单 key `shortcut_bindings`。
/// 仅存用户自定义项；缺省动作读 [shortcutActions] 默认绑定。
/// 构造时读 prefs（惰性，pump 时构造）；改键 → notifyListeners → 壳/列表层
/// watch 重建 Shortcuts 表，即时生效。
class ShortcutSettingsController extends ChangeNotifier {
  ShortcutSettingsController(this._prefs) {
    _load();
  }

  static const String prefsKey = 'shortcut_bindings';

  final SharedPreferences _prefs;
  Map<String, ShortcutBinding> _custom = {};

  /// 动作当前绑定：自定义优先，缺省走默认（不可解绑，永远有值）。
  ShortcutBinding bindingFor(String actionId) =>
      _custom[actionId] ?? actionById(actionId).defaultBinding;

  /// 保存候选绑定：冲突返回占用动作 id（不保存不通知）；成功返回 null。
  /// 冲突按【展开键集】比对——含 control↔meta 派生变体，杜绝「存储形不冲突、
  /// 运行时互踩」（如 A=Ctrl+T 与 B=Cmd+T：A 派生 Cmd+T 撞 B）。
  String? trySetBinding(String actionId, ShortcutBinding binding) {
    final candidate = activatorsFor(binding);
    for (final other in shortcutActions) {
      if (other.id == actionId) continue;
      if (_overlaps(candidate, activatorsFor(bindingFor(other.id)))) {
        return other.id;
      }
    }
    _custom = {..._custom, actionId: binding};
    notifyListeners();
    unawaited(_save());
    return null;
  }

  /// 恢复默认：清空自定义 + 删除 prefs key + notify（UI 全表回默认）。
  Future<void> resetAll() async {
    _custom = {};
    await _prefs.remove(prefsKey);
    notifyListeners();
  }

  /// 加载：坏条目（非 map / 未知 actionId / 非法键名）防御性忽略；
  /// 整串坏 JSON → 空 map 全默认——坏数据永不崩溃，回退默认即「恢复出厂」。
  void _load() {
    final raw = _prefs.getString(prefsKey);
    if (raw == null) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return; // 整串坏 JSON → 全默认
    }
    if (decoded is! Map<String, dynamic>) return;
    for (final entry in decoded.entries) {
      final id = entry.key;
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      if (!shortcutActions.any((a) => a.id == id)) continue;
      try {
        _custom[id] = ShortcutBinding.fromJson(value);
      } on FormatException {
        // 非法键名/缺 key → 忽略该项
      }
    }
  }

  Future<void> _save() async {
    await _prefs.setString(prefsKey, jsonEncode({
      for (final e in _custom.entries) e.key: e.value.toJson(),
    }));
  }

  bool _overlaps(List<ShortcutActivator> a, List<ShortcutActivator> b) {
    final ids = b.map(_activatorId).toSet();
    return a.any((x) => ids.contains(_activatorId(x)));
  }
}

String _activatorId(ShortcutActivator activator) {
  final s = activator as SingleActivator;
  return '${s.trigger.keyId}|${s.control ? 1 : 0}|${s.meta ? 1 : 0}|${s.shift ? 1 : 0}|${s.alt ? 1 : 0}';
}

final shortcutSettingsControllerProvider =
    ChangeNotifierProvider<ShortcutSettingsController>(
  (ref) => ShortcutSettingsController(ref.watch(sharedPreferencesProvider)),
);
```

- [x] **Step 4: 新建 `test/core/shortcut_settings_controller_test.dart`（完整文件）**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/core/shortcuts/shortcut_bindings.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> prefsWith(
      [Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('默认绑定：collect=N 无修饰；navInbox=Digit1+control；toggle=KeyT+control+shift',
      () async {
    final prefs = await prefsWith();
    final controller = ShortcutSettingsController(prefs);
    expect(controller.bindingFor('collect').normalizedId, 'KeyN|0|0|0|0');
    expect(controller.bindingFor('navInbox').normalizedId, 'Digit1|1|0|0|0');
    expect(controller.bindingFor('toggleAlwaysOnTop').normalizedId,
        'KeyT|1|0|1|0');
    // 16 动作全部可解析出绑定（不可解绑，永远有值）。
    for (final action in shortcutActions) {
      expect(controller.bindingFor(action.id).normalizedId,
          action.defaultBinding.normalizedId);
    }
  });

  test('加载：seed JSON → bindingFor 返回存储值', () async {
    final prefs = await prefsWith({
      'shortcut_bindings': jsonEncode({'collect': {'key': 'KeyX'}}),
    });
    final controller = ShortcutSettingsController(prefs);
    expect(controller.bindingFor('collect').normalizedId, 'KeyX|0|0|0|0');
    expect(controller.bindingFor('navInbox').normalizedId, 'Digit1|1|0|0|0');
  });

  test('保存：trySetBinding 成功返回 null + prefs 落 JSON + notify', () async {
    final prefs = await prefsWith();
    final controller = ShortcutSettingsController(prefs);
    var notified = 0;
    controller.addListener(() => notified++);
    final conflict = controller.trySetBinding(
        'collect', const ShortcutBinding(key: 'KeyA', control: true, shift: true));
    expect(conflict, isNull);
    expect(notified, 1);
    final saved = jsonDecode(prefs.getString('shortcut_bindings')!)
        as Map<String, dynamic>;
    expect(saved['collect'], {'key': 'KeyA', 'control': true, 'shift': true});
  });

  test('冲突拒绝：Ctrl+T 已被 collect 占用 → 返回 collect 且状态/JSON 不变', () async {
    final prefs = await prefsWith();
    final controller = ShortcutSettingsController(prefs);
    expect(controller.trySetBinding(
        'collect', const ShortcutBinding(key: 'KeyT', control: true)), isNull);
    final conflict = controller.trySetBinding(
        'navInbox', const ShortcutBinding(key: 'KeyT', control: true));
    expect(conflict, 'collect');
    expect(controller.bindingFor('navInbox').normalizedId, 'Digit1|1|0|0|0');
    expect(jsonDecode(prefs.getString('shortcut_bindings')!),
        {'collect': {'key': 'KeyT', 'control': true}});
  });

  test('派生冲突（关键）：collect=Ctrl+T 后 Cmd+T 撞派生变体 → 返回 collect', () async {
    final prefs = await prefsWith();
    final controller = ShortcutSettingsController(prefs);
    expect(controller.trySetBinding(
        'collect', const ShortcutBinding(key: 'KeyT', control: true)), isNull);
    final conflict = controller.trySetBinding(
        'navInbox', const ShortcutBinding(key: 'KeyT', meta: true));
    expect(conflict, 'collect');
    expect(controller.bindingFor('navInbox').normalizedId, 'Digit1|1|0|0|0');
  });

  test('恢复默认：resetAll 清空自定义 + 删 key + notify', () async {
    final prefs = await prefsWith({
      'shortcut_bindings': jsonEncode({'collect': {'key': 'KeyX'}}),
    });
    final controller = ShortcutSettingsController(prefs);
    expect(controller.bindingFor('collect').normalizedId, 'KeyX|0|0|0|0');
    var notified = 0;
    controller.addListener(() => notified++);
    await controller.resetAll();
    expect(controller.bindingFor('collect').normalizedId, 'KeyN|0|0|0|0');
    expect(prefs.getString('shortcut_bindings'), isNull);
    expect(notified, 1);
  });

  group('JSON 编解码', () {
    test('round-trip：仅序列化 true 修饰符；缺省 false', () {
      const binding = ShortcutBinding(key: 'KeyA', control: true, shift: true);
      expect(binding.toJson(),
          {'key': 'KeyA', 'control': true, 'shift': true});
      final decoded = ShortcutBinding.fromJson(binding.toJson());
      expect(decoded.normalizedId, binding.normalizedId);
      const plain = ShortcutBinding(key: 'KeyN');
      expect(ShortcutBinding.fromJson(plain.toJson()).normalizedId,
          'KeyN|0|0|0|0');
    });

    test('swapControlMeta：Ctrl ↔ Meta 互换', () {
      const binding = ShortcutBinding(key: 'KeyT', control: true, shift: true);
      expect(binding.swapControlMeta().normalizedId, 'KeyT|0|1|1|0');
    });

    test('坏数据防御：条目非 map / 未知 actionId / 非法键名 → 忽略该项', () async {
      final prefs = await prefsWith({
        'shortcut_bindings': jsonEncode({
          'collect': 'notamap',
          'unknownId': {'key': 'KeyA'},
          'navInbox': {'key': 'NotAKey'},
          'navToday': {'key': 'Digit2', 'control': true},
        }),
      });
      final controller = ShortcutSettingsController(prefs);
      // collect/navInbox 坏条目忽略回默认；navToday 合法条目保留。
      expect(controller.bindingFor('collect').normalizedId, 'KeyN|0|0|0|0');
      expect(controller.bindingFor('navInbox').normalizedId, 'Digit1|1|0|0|0');
      expect(controller.bindingFor('navToday').normalizedId, 'Digit2|1|0|0|0');
    });

    test('整串坏 JSON → 空 map 全默认', () async {
      final prefs = await prefsWith({'shortcut_bindings': 'not json{{{'});
      final controller = ShortcutSettingsController(prefs);
      for (final action in shortcutActions) {
        expect(controller.bindingFor(action.id).normalizedId,
            action.defaultBinding.normalizedId);
      }
    });
  });
}
```

- [x] **Step 5: analyze + 全量测试门禁**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter analyze 2>&1 | Select-Object -Last 3
flutter test 2>&1 | Select-Object -Last 1
```

Expected: analyze 汇总行 0 error 且 0 warning；`flutter test` → `All tests passed!`（217 基线 + 本 Task 10 个新单元测试全绿）。

- [x] **Step 6: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/core/shortcuts test/core/shortcut_settings_controller_test.dart
git commit -m 'feat(shortcuts): 快捷键领域层——16 动作规范表 + ShortcutBinding + 设置控制器（含单元测试）'
```

Expected: 提交成功。
### Task 4: 快捷键配置 UI（配置页 + 录键弹窗 + 动作名集中解析）+ 测试

**Files:**
- Create: `lib/features/settings/shortcuts/shortcut_labels.dart` / `shortcut_settings_page.dart` / `capture_binding_dialog.dart`
- Create: `test/widget/shortcut_settings_page_test.dart` / `test/widget/capture_binding_dialog_test.dart`

- [x] **Step 1: 新建 `lib/features/settings/shortcuts/shortcut_labels.dart`（完整文件）**

```dart
import 'package:settle_app/i18n/l10n/app_localizations.dart';

/// 16 动作 labelKey → l10n 文本集中解析（与壳层 `_labelOf` 同款 switch 模式）：
/// 配置页行 title 与录键弹窗冲突文案共用，避免两处各写一份。
String actionLabel(AppLocalizations l10n, String labelKey) {
  switch (labelKey) {
    case 'actionCollect':
      return l10n.actionCollect;
    case 'actionNavInbox':
      return l10n.actionNavInbox;
    case 'actionNavToday':
      return l10n.actionNavToday;
    case 'actionNavUpcoming':
      return l10n.actionNavUpcoming;
    case 'actionNavAnytime':
      return l10n.actionNavAnytime;
    case 'actionNavSomeday':
      return l10n.actionNavSomeday;
    case 'actionNavProjects':
      return l10n.actionNavProjects;
    case 'actionNavContexts':
      return l10n.actionNavContexts;
    case 'actionNavWaiting':
      return l10n.actionNavWaiting;
    case 'actionNavLogbook':
      return l10n.actionNavLogbook;
    case 'actionNavReview':
      return l10n.actionNavReview;
    case 'actionListUp':
      return l10n.actionListUp;
    case 'actionListDown':
      return l10n.actionListDown;
    case 'actionListComplete':
      return l10n.actionListComplete;
    case 'actionListDelete':
      return l10n.actionListDelete;
    case 'actionToggleAlwaysOnTop':
      return l10n.actionToggleAlwaysOnTop;
    default:
      throw ArgumentError('未知快捷键动作 labelKey: $labelKey');
  }
}
```

- [x] **Step 2: 新建 `lib/features/settings/shortcuts/shortcut_settings_page.dart`（完整文件）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/core/shortcuts/shortcut_bindings.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'capture_binding_dialog.dart';
import 'shortcut_labels.dart';

/// 快捷键配置页（桌面设置 spec 功能一 §6）：两组 16 行 + 键帽 + 恢复默认。
/// 经设置页 Navigator.push 推入（模态子配置语义，与指南页外壳切页区分）。
class ShortcutSettingsPage extends ConsumerWidget {
  const ShortcutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.watch(shortcutSettingsControllerProvider);
    final bridge = ref.watch(platformBridgeProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shortcutsTitle),
        actions: [
          TextButton(
            key: const Key('shortcuts_reset'),
            onPressed: () => _confirmReset(context, ref, l10n),
            child: Text(l10n.shortcutsReset),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          _groupTitle(tokens, l10n.shortcutsGroupGlobal),
          for (final action in shortcutActions
              .where((a) => a.layer == ShortcutLayer.shell))
            _row(context, ref, tokens, l10n, bridge.isMacOS, action),
          _groupTitle(tokens, l10n.shortcutsGroupList),
          for (final action in shortcutActions
              .where((a) => a.layer == ShortcutLayer.list))
            _row(context, ref, tokens, l10n, bridge.isMacOS, action),
        ],
      ),
    );
  }

  Widget _groupTitle(AppTokenSet tokens, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: tokens.muted,
          ),
        ),
      );

  Widget _row(BuildContext context, WidgetRef ref, AppTokenSet tokens,
      AppLocalizations l10n, bool isMacOS, ShortcutAction action) {
    final binding = ref
        .read(shortcutSettingsControllerProvider)
        .bindingFor(action.id);
    return ListTile(
      key: Key('shortcut_row_${action.id}'),
      title: Text(actionLabel(l10n, action.labelKey)),
      trailing: _Keycap(
        tokens: tokens,
        binding: binding,
        isMacOS: isMacOS,
        l10n: l10n,
      ),
      onTap: () => _capture(context, action),
    );
  }

  Future<void> _capture(BuildContext context, ShortcutAction action) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CaptureBindingDialog(actionId: action.id),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.shortcutsResetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const Key('shortcuts_reset_confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.shortcutsReset),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(shortcutSettingsControllerProvider).resetAll();
    }
  }
}

/// 键帽：1px hairline 圆角 6 小盒，修饰符符号 + 键名，'+' 拼接（spec §6）。
/// 主修饰符合并展示：meta&&!control → Cmd；control&&!meta → macOS ? Cmd : Ctrl；
/// 双真 → Ctrl+Cmd 并列；其后 Shift → Alt。纯单键绑定 → 仅键名。
class _Keycap extends StatelessWidget {
  const _Keycap({
    required this.tokens,
    required this.binding,
    required this.isMacOS,
    required this.l10n,
  });

  final AppTokenSet tokens;
  final ShortcutBinding binding;
  final bool isMacOS;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (binding.meta && !binding.control) l10n.keyCmd,
      if (binding.control && !binding.meta)
        (isMacOS ? l10n.keyCmd : l10n.keyCtrl),
      if (binding.control && binding.meta) '${l10n.keyCtrl}+${l10n.keyCmd}',
      if (binding.shift) l10n.keyShift,
      if (binding.alt) l10n.keyAlt,
      _keyLabel(binding.key),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.stroke, width: 1),
      ),
      child: Text(
        parts.join('+'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.chipText,
        ),
      ),
    );
  }
}

/// 键帽键名映射（spec §6 规则 3）：DigitN → keyLabel('N')、KeyX → keyLabel('X')
/// （SDK `LogicalKeyboardKey.keyLabel` 对可打印键返回大写字符，release 可用）；
/// Enter/Delete/Space 特判原名（与 keyLabel 同名，显式特判防未来 SDK 变更）；
/// 未知键 → 键名原样。
String _keyLabel(String keyName) {
  if (keyName == 'Enter' || keyName == 'Delete' || keyName == 'Space') {
    return keyName;
  }
  final label = logicalKeyForKeyName(keyName)?.keyLabel ?? '';
  return label.isEmpty ? keyName : label;
}
```

- [x] **Step 3: 新建 `lib/features/settings/shortcuts/capture_binding_dialog.dart`（完整文件）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/core/shortcuts/shortcut_bindings.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'shortcut_labels.dart';

/// 录键弹窗（桌面设置 spec 功能一 §7）：模态，内嵌 Focus(autofocus) 捕获键盘。
/// 在独立 Overlay 路由内获焦，按键沿 Overlay/Navigator 祖先链冒泡，不进入
/// 壳层 Shortcuts 子树（与收集弹窗同款隔离，弹窗内按键不与应用快捷键互扰）。
/// Esc（含组合）取消；纯修饰键提示；冲突拒绝显示占用动作名；成功即关。
class CaptureBindingDialog extends ConsumerStatefulWidget {
  const CaptureBindingDialog({super.key, required this.actionId});

  /// 配置哪个动作（spec 动作表 id，如 'collect'）。
  final String actionId;

  @override
  ConsumerState<CaptureBindingDialog> createState() =>
      _CaptureBindingDialogState();
}

class _CaptureBindingDialogState extends ConsumerState<CaptureBindingDialog> {
  /// 状态行文案：冲突/纯修饰键提示；初始为空（不显示）。
  String _status = '';

  static bool _isModifier(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.metaLeft ||
      key == LogicalKeyboardKey.metaRight ||
      key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight ||
      key == LogicalKeyboardKey.altLeft ||
      key == LogicalKeyboardKey.altRight;

  KeyEventResult _handleKey(LogicalKeyboardKey logicalKey) {
    final l10n = AppLocalizations.of(context)!;
    // Esc 保留为取消键（含 Ctrl+Esc 等组合），不可被捕获。
    if (logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final control = pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
    final meta = pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
    final shift = pressed.contains(LogicalKeyboardKey.shiftLeft) ||
        pressed.contains(LogicalKeyboardKey.shiftRight);
    final alt = pressed.contains(LogicalKeyboardKey.altLeft) ||
        pressed.contains(LogicalKeyboardKey.altRight);
    // 主键为修饰键且当前按住的全是修饰键 → 提示继续等待（Ctrl+Shift 亦属此类）。
    if (_isModifier(logicalKey) && !pressed.any((k) => !_isModifier(k))) {
      setState(() => _status = l10n.captureModifiersOnlyHint);
      return KeyEventResult.handled;
    }
    final String keyName;
    try {
      keyName = keyNameOf(logicalKey);
    } on FormatException {
      return KeyEventResult.handled; // 不可序列化键（媒体键等）：忽略保持等待。
    }
    final binding = ShortcutBinding(
      key: keyName,
      control: control,
      meta: meta,
      shift: shift,
      alt: alt,
    );
    final conflictId = ref
        .read(shortcutSettingsControllerProvider)
        .trySetBinding(widget.actionId, binding);
    if (conflictId == null) {
      Navigator.of(context).pop(); // 成功：关闭，页面经 watch 自动刷新键帽。
    } else {
      final conflictAction = actionById(conflictId);
      setState(() => _status =
          l10n.captureConflict(actionLabel(l10n, conflictAction.labelKey)));
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = actionById(widget.actionId);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final tokens = isLight ? AppTokens.light : AppTokens.dark;
    return AlertDialog(
      title: Text(actionLabel(l10n, action.labelKey)),
      content: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent || event.repeat) {
            return KeyEventResult.ignored;
          }
          return _handleKey(event.logicalKey);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.capturePrompt),
            const SizedBox(height: 4),
            Text(
              l10n.captureEscHint,
              style: TextStyle(fontSize: 12, color: tokens.muted),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _status,
                style: TextStyle(fontSize: 13, color: tokens.danger),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [x] **Step 4: 新建 `test/widget/capture_binding_dialog_test.dart`（完整文件）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/shortcuts/shortcut_bindings.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
import 'package:settle_app/features/settings/shortcuts/capture_binding_dialog.dart';
import 'widget_utils.dart';

void main() {
  /// 弹窗宿主：按钮点开 CaptureBindingDialog（collect 动作）。
  Future<TestEnv> pumpDialog(WidgetTester tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const CaptureBindingDialog(actionId: 'collect'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return env;
  }

  /// 发送完整 down/up 序列（避免硬件键盘状态泄漏）。
  Future<void> sendChord(WidgetTester tester,
      {bool ctrl = false, bool shift = false, bool meta = false}) async {
    if (ctrl) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    if (meta) await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    if (meta) await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (ctrl) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('录键成功：Ctrl+Shift+A → 弹窗关闭 + 绑定生效', (tester) async {
    final env = await pumpDialog(tester);
    await sendChord(tester, ctrl: true, shift: true);
    await tester.pumpAndSettle();
    expect(find.byType(CaptureBindingDialog), findsNothing);
    final saved = env.prefs.getString('shortcut_bindings');
    expect(saved, contains('"key": "KeyA"'));
    expect(saved, contains('"control": true'));
    expect(saved, contains('"shift": true'));
    await env.db.close();
  });

  testWidgets('Esc 取消：弹窗关闭 + 状态不变', (tester) async {
    final env = await pumpDialog(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CaptureBindingDialog), findsNothing);
    expect(env.prefs.getString('shortcut_bindings'), isNull);
    await env.db.close();
  });

  testWidgets('含 Esc 组合取消：Ctrl+Esc 亦取消', (tester) async {
    final env = await pumpDialog(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(CaptureBindingDialog), findsNothing);
    expect(env.prefs.getString('shortcut_bindings'), isNull);
    await env.db.close();
  });

  testWidgets('冲突拒绝：navInbox 预占 Ctrl+T → 录 Ctrl+T 显占用名，弹窗未关',
      (tester) async {
    final env = await TestEnv.create();
    await env.prefs.setString('shortcut_bindings',
        '{"navInbox": {"key": "KeyT", "control": true}}');
    await tester.pumpWidget(env.wrap(Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const CaptureBindingDialog(actionId: 'collect'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // 预置绑定在控制器构造（pump 时）读入。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.byType(CaptureBindingDialog), findsOneWidget);
    expect(find.text('This shortcut is already used by Inbox'), findsOneWidget);
    // 冲突未保存：bindingFor('collect') 仍为默认 KeyN。
    expect(env.prefs.getString('shortcut_bindings'),
        '{"navInbox": {"key": "KeyT", "control": true}}');
    await env.db.close();
  });

  testWidgets('纯修饰键忽略：只按 Shift → 提示可见，弹窗未关', (tester) async {
    final env = await pumpDialog(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(find.byType(CaptureBindingDialog), findsOneWidget);
    expect(find.text('Include at least one non-modifier key'), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await env.db.close();
  });
}
```

（注：default locale 为 en——冲突文案与纯修饰键提示按英文断言；prefs seed 必须在 `pumpWidget` 之前（控制器构造时读入）。`dart:convert` 未用到（断言用 contains 字符串），无需引入。）

- [x] **Step 5: 新建 `test/widget/shortcut_settings_page_test.dart`（完整文件）**

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/features/settings/shortcuts/shortcut_settings_page.dart';
import 'widget_utils.dart';

void main() {
  void usePlatform(TargetPlatform platform) {
    debugDefaultTargetPlatformOverride = platform;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  testWidgets('16 行渲染：两组标题 + 全部 shortcut_row_* 存在', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Lists'), findsOneWidget);
    for (final action in shortcutActions) {
      expect(find.byKey(Key('shortcut_row_${action.id}')), findsOneWidget);
    }
    await env.db.close();
  });

  testWidgets('键帽：Windows 下 navInbox 行显 Ctrl+1；macOS 下显 Cmd+1',
      (tester) async {
    usePlatform(TargetPlatform.windows);
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Ctrl+1'),
      ),
      findsOneWidget,
    );
    await env.db.close();
  });

  testWidgets('键帽 macOS：navInbox 行显 Cmd+1（平台自适应）', (tester) async {
    usePlatform(TargetPlatform.macOS);
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Cmd+1'),
      ),
      findsOneWidget,
    );
    await env.db.close();
  });

  testWidgets('恢复默认：预置自定义 → 确认框 → 键帽回默认', (tester) async {
    final env = await TestEnv.create();
    await env.prefs.setString('shortcut_bindings',
        jsonEncode({'navInbox': {'key': 'KeyA', 'control': true, 'shift': true}}));
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Ctrl+Shift+A'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('shortcuts_reset')));
    await tester.pumpAndSettle();
    expect(find.text('Reset all shortcuts to their defaults?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shortcuts_reset_confirm')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_navInbox')),
        matching: find.text('Ctrl+1'),
      ),
      findsOneWidget,
    );
    expect(env.prefs.getString('shortcut_bindings'), isNull);
    await env.db.close();
  });

  testWidgets('录键后更新：点 collect 行 → 录 Ctrl+X → 键帽变 Ctrl+X',
      (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ShortcutSettingsPage()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shortcut_row_collect')));
    await tester.pumpAndSettle();
    // 录 Ctrl+X。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyX);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('shortcut_row_collect')),
        matching: find.text('Ctrl+X'),
      ),
      findsOneWidget,
    );
    await env.db.close();
  });
}
```

（注：default locale 为 en——键帽与确认框文案按英文断言；prefs seed 必须在 `pumpWidget` 之前（控制器构造时读入）；`flutter/services.dart` 提供 `LogicalKeyboardKey` 供录键测试序列使用。）

- [x] **Step 6: analyze + 全量测试门禁**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter analyze 2>&1 | Select-Object -Last 3
flutter test 2>&1 | Select-Object -Last 1
```

Expected: analyze 汇总行 0 error 且 0 warning；`flutter test` → `All tests passed!`（217 基线 + 本 Task 10 个新 widget 测试全绿）。

- [x] **Step 7: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/features/settings/shortcuts test/widget/shortcut_settings_page_test.dart test/widget/capture_binding_dialog_test.dart
git commit -m 'feat(shortcuts): 快捷键配置页 + 录键弹窗 + 动作名集中解析（含测试）'
```

Expected: 提交成功。
### Task 5: 窗口置顶（WindowController 唯一状态源 + main 启动接线 + 设置页双 tile）+ Windows 构建冒烟

**Files:**
- Modify: `test/widget/widget_utils.dart`（新增 FakeWindowService）
- Create: `lib/app/window_controller.dart` / `test/core/window_controller_test.dart`
- Modify: `lib/main.dart`（bridge.detect + createWindowService + ensureInitialized + restoreAlwaysOnTop + override）
- Modify: `lib/features/settings/settings_page.dart`（imports + 两桌面 tile 插入）
- Modify: `test/widget/settings_page_test.dart`（新增 3 用例）
- Gate: `flutter build windows --release`

- [ ] **Step 1: `widget_utils.dart` 新增 FakeWindowService + import**

改前（文件头部 import 块 L1-9 的末尾两行）：

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../test_utils.dart';
```

改后：

```dart
import 'package:settle_app/core/platform/window_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_utils.dart';
```

（即把 `core/platform/window_service.dart` import 插到 shared_preferences 之前；import 排序按字母：`settle_app` 在 `shared_preferences` 前。）

改前（FakeBackupGateway 类之后、TestEnv 注释之前）：

```dart
class FakeBackupGateway implements BackupFileGateway {
  String? savedJson;
  String? pickedJson;

  @override
  Future<String?> saveBackup(String json) async {
    savedJson = json;
    return '/fake/settle_backup.json';
  }

  @override
  Future<String?> pickBackupJson() async => pickedJson;
}
```

改后（类后插入 FakeWindowService）：

```dart
class FakeBackupGateway implements BackupFileGateway {
  String? savedJson;
  String? pickedJson;

  @override
  Future<String?> saveBackup(String json) async {
    savedJson = json;
    return '/fake/settle_backup.json';
  }

  @override
  Future<String?> pickBackupJson() async => pickedJson;
}

/// Fake 窗口服务（桌面设置 spec 测试）：记录调用，不触真实插件。
/// 凡触发置顶 toggle 的 widget 用例必须 override windowServiceProvider 为此
/// fake，否则 DesktopWindowService 会调真实插件抛 MissingPluginException。
class FakeWindowService implements WindowService {
  int ensureInitializedCalls = 0;
  final List<bool> setAlwaysOnTopCalls = [];

  @override
  Future<void> ensureInitialized() async {
    ensureInitializedCalls++;
  }

  @override
  Future<void> setAlwaysOnTop(bool value) async {
    setAlwaysOnTopCalls.add(value);
  }
}
```

- [ ] **Step 2: 新建 `lib/app/window_controller.dart`（完整文件）**

```dart
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/platform/window_service.dart';
import 'package:settle_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 置顶持久化 key（纯新增，无迁移；缺省/false = 不置顶）。
const String alwaysOnTopPrefsKey = 'always_on_top';

/// 窗口置顶唯一状态源：设置页开关与 toggleAlwaysOnTop 快捷键都走它，实时同步
/// UI 与 OS 窗口——`toggle()` 是全仓唯一写点，无第二处直接调 setAlwaysOnTop/prefs。
class WindowController extends ChangeNotifier {
  WindowController(this._prefs, this._windowService)
      : _alwaysOnTop = _prefs.getBool(alwaysOnTopPrefsKey) ?? false;

  final SharedPreferences _prefs;
  final WindowService _windowService;
  bool _alwaysOnTop;

  bool get alwaysOnTop => _alwaysOnTop;

  Future<void> toggle() async {
    _alwaysOnTop = !_alwaysOnTop;
    notifyListeners();
    await _windowService.setAlwaysOnTop(_alwaysOnTop); // 移动端 = Noop
    await _prefs.setBool(alwaysOnTopPrefsKey, _alwaysOnTop);
  }
}

/// 启动恢复（main() 调用）：flag 为 true 时置顶；缺省/false 不调用（零动作）。
/// 与控制器构造读同一 key → 窗口状态与 UI 状态启动即一致。
Future<void> restoreAlwaysOnTop(
    SharedPreferences prefs, WindowService windowService) async {
  if (prefs.getBool(alwaysOnTopPrefsKey) ?? false) {
    await windowService.setAlwaysOnTop(true);
  }
}

final windowControllerProvider = ChangeNotifierProvider<WindowController>(
  (ref) => WindowController(
    ref.watch(sharedPreferencesProvider),
    ref.watch(windowServiceProvider),
  ),
);
```

- [ ] **Step 3: `lib/main.dart` 接线（精确改前/改后）**

改前（完整文件）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/app.dart';
import 'package:settle_app/data/app_database.dart';
import 'package:settle_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const SettleApp(),
  ));
}
```

改后（完整文件）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/app.dart';
import 'package:settle_app/app/window_controller.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/core/platform/window_service.dart';
import 'package:settle_app/data/app_database.dart';
import 'package:settle_app/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final prefs = await SharedPreferences.getInstance();
  final bridge = PlatformBridge.detect();
  final windowService = createWindowService(isDesktop: bridge.isDesktop);
  await windowService.ensureInitialized(); // 桌面初始化原生窗口插件；移动 no-op
  await restoreAlwaysOnTop(prefs, windowService); // 启动恢复：上次置顶 → 恢复
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      windowServiceProvider.overrideWithValue(windowService), // 与 main 构造同一实例
    ],
    child: const SettleApp(),
  ));
}
```

- [ ] **Step 4: `settings_page.dart` 新增两桌面 tile（精确改前/改后）**

改前（import 块，L1-9 全文）：

```dart
import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/features/settings/backup_file_gateway.dart';
import 'package:settle_app/features/settings/settings_controller.dart';
```

改后：

```dart
import 'package:flutter/material.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/app/window_controller.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/features/settings/shortcuts/shortcut_settings_page.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/features/settings/backup_file_gateway.dart';
import 'package:settle_app/features/settings/settings_controller.dart';
```

改前（tile 区，AI 占位 tile 与 GTD 指南 tile）：

```dart
          glassRow(
            child: ListTile(
              enabled: false,
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(l10n.aiPlaceholder),
            ),
          ),
          glassRow(
            child: ListTile(
              key: const Key('settings_guide_tile'),
```

改后：

```dart
          glassRow(
            child: ListTile(
              enabled: false,
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(l10n.aiPlaceholder),
            ),
          ),
          // 桌面专属设置（桌面设置 spec）：bridge.isDesktop 门控，移动端不渲染；
          // 置顶开关与快捷键配置入口，置于 AI 占位与 GTD 指南之间。
          if (ref.watch(platformBridgeProvider).isDesktop) ...[
            glassRow(
              child: SwitchListTile(
                key: const Key('settings_always_on_top_tile'),
                secondary: const Icon(Icons.push_pin_outlined),
                title: Text(l10n.settingsAlwaysOnTop),
                subtitle: Text(l10n.settingsAlwaysOnTopHint),
                value: ref.watch(windowControllerProvider).alwaysOnTop,
                onChanged: (_) => ref.read(windowControllerProvider).toggle(),
              ),
            ),
            glassRow(
              child: ListTile(
                key: const Key('settings_shortcuts_tile'),
                leading: const Icon(Icons.keyboard_outlined),
                title: Text(l10n.settingsShortcuts),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ShortcutSettingsPage(),
                  ),
                ),
              ),
            ),
          ],
          glassRow(
            child: ListTile(
              key: const Key('settings_guide_tile'),
```

- [ ] **Step 5: 新建 `test/core/window_controller_test.dart`（完整文件）**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/app/window_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/widget_utils.dart';

void main() {
  Future<SharedPreferences> prefsWith({bool? alwaysOnTop}) async {
    SharedPreferences.setMockInitialValues(
        {if (alwaysOnTop != null) alwaysOnTopPrefsKey: alwaysOnTop});
    return SharedPreferences.getInstance();
  }

  test('初始状态：缺省 false；seed true → true', () async {
    final prefs = await prefsWith();
    final controller = WindowController(prefs, FakeWindowService());
    expect(controller.alwaysOnTop, false);

    final prefs2 = await prefsWith(alwaysOnTop: true);
    final controller2 = WindowController(prefs2, FakeWindowService());
    expect(controller2.alwaysOnTop, true);
  });

  test('toggle 双向：状态 + fake 调用 + prefs 同步', () async {
    final prefs = await prefsWith();
    final service = FakeWindowService();
    final controller = WindowController(prefs, service);
    await controller.toggle();
    expect(controller.alwaysOnTop, true);
    expect(service.setAlwaysOnTopCalls, [true]);
    expect(prefs.getBool(alwaysOnTopPrefsKey), true);
    await controller.toggle();
    expect(controller.alwaysOnTop, false);
    expect(service.setAlwaysOnTopCalls, [true, false]);
    expect(prefs.getBool(alwaysOnTopPrefsKey), false);
  });

  test('restoreAlwaysOnTop 三态：true 恢复 / 缺省与 false 零调用', () async {
    final prefsTrue = await prefsWith(alwaysOnTop: true);
    final serviceTrue = FakeWindowService();
    await restoreAlwaysOnTop(prefsTrue, serviceTrue);
    expect(serviceTrue.setAlwaysOnTopCalls, [true]);

    final prefsDefault = await prefsWith();
    final serviceDefault = FakeWindowService();
    await restoreAlwaysOnTop(prefsDefault, serviceDefault);
    expect(serviceDefault.setAlwaysOnTopCalls, isEmpty);

    final prefsFalse = await prefsWith(alwaysOnTop: false);
    final serviceFalse = FakeWindowService();
    await restoreAlwaysOnTop(prefsFalse, serviceFalse);
    expect(serviceFalse.setAlwaysOnTopCalls, isEmpty);
  });
}
```

- [ ] **Step 6: `settings_page_test.dart` 新增 3 用例**

改前（文件末尾 main 收尾 `}` 前，最后一个用例收尾 `  });`）：

```dart
    await tester.tap(find.byKey(const Key('settings_guide_tile')));
    expect(opened, isTrue);
    await env.db.close();
  });
}
```

改后：

```dart
    await tester.tap(find.byKey(const Key('settings_guide_tile')));
    expect(opened, isTrue);
    await env.db.close();
  });

  testWidgets('桌面：置顶开关与快捷键入口两 tile 存在，开关交互落 fake + prefs',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final env = await TestEnv.create();
    final fake = FakeWindowService();
    await tester.pumpWidget(env.wrap(
      SettingsPage(onOpenGuide: () {}),
      extraOverrides: [windowServiceProvider.overrideWithValue(fake)],
    ));
    expect(find.byKey(const Key('settings_always_on_top_tile')), findsOneWidget);
    expect(find.byKey(const Key('settings_shortcuts_tile')), findsOneWidget);
    // 置顶开关：点 → fake 记录 setAlwaysOnTop(true) + prefs；再点 → false。
    await tester.tap(find.byKey(const Key('settings_always_on_top_tile')));
    await tester.pumpAndSettle();
    expect(fake.setAlwaysOnTopCalls, [true]);
    expect(env.prefs.getBool('always_on_top'), true);
    await tester.tap(find.byKey(const Key('settings_always_on_top_tile')));
    await tester.pumpAndSettle();
    expect(fake.setAlwaysOnTopCalls, [true, false]);
    expect(env.prefs.getBool('always_on_top'), false);
    await env.db.close();
  });

  testWidgets('桌面：快捷键入口导航到配置页（AppBar shortcutsTitle）', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(SettingsPage(onOpenGuide: () {})));
    await tester.tap(find.byKey(const Key('settings_shortcuts_tile')));
    await tester.pumpAndSettle();
    expect(find.byType(ShortcutSettingsPage), findsOneWidget);
    expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('移动（bridge override 非桌面）：两 tile 不渲染', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(
      SettingsPage(onOpenGuide: () {}),
      extraOverrides: [
        platformBridgeProvider.overrideWithValue(
            const PlatformBridge(isDesktop: false, isMacOS: false)),
      ],
    ));
    expect(find.byKey(const Key('settings_always_on_top_tile')), findsNothing);
    expect(find.byKey(const Key('settings_shortcuts_tile')), findsNothing);
    await env.db.close();
  });
}
```

改前（`settings_page_test.dart` import 块）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/settings/settings_page.dart';
import 'widget_utils.dart';
```

改后：

```dart
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/core/platform/window_service.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/settings/settings_page.dart';
import 'package:settle_app/features/settings/shortcuts/shortcut_settings_page.dart';
import 'widget_utils.dart';
```

- [ ] **Step 7: analyze + 全量测试门禁**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter analyze 2>&1 | Select-Object -Last 3
flutter test 2>&1 | Select-Object -Last 1
```

Expected: analyze 汇总行 0 error 且 0 warning；`flutter test` → `All tests passed!`（217 基线 + 本 Task 3 个单元 + 3 个 widget 测试全绿）。

- [ ] **Step 8: Windows 原生构建冒烟（window_manager 硬门禁，本轮关键新增门禁）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter build windows --release
```

Expected: 构建成功（输出 `Building Windows application...` 后正常结束，退出码 0，`build/windows/x64/runner/Release/` 生成可执行文件）。若原生编译报错（window_manager 平台通道编译问题），停在本步修复后再提交。

- [ ] **Step 9: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/app/window_controller.dart lib/main.dart lib/features/settings/settings_page.dart test/core/window_controller_test.dart test/widget/widget_utils.dart test/widget/settings_page_test.dart
git commit -m 'feat(window): 窗口置顶——WindowController 唯一状态源 + 设置页双 tile + 启动恢复（含测试 + Windows 构建冒烟）'
```

Expected: 提交成功。
### Task 6: 双层接线（壳层 + 列表层配置驱动快捷键表 + 置顶快捷键）+ wiring 测试

**Files:**
- Modify: `lib/app/responsive_shell.dart`（imports / 构建表 / `_ToggleAlwaysOnTopIntent` / 删 `_shortcutsEnabled` / 加 `_intentFor`）
- Modify: `lib/features/task/task_list_view.dart`（imports / 拖拽注释登记 / 门禁与构建表）
- Create: `test/widget/shortcut_wiring_test.dart` / `test/widget/task_list_wiring_test.dart`
- 回归门禁：`test/widget/responsive_shell_test.dart` 与 `test/widget/task_list_view_test.dart` **不改一行**原样通过

#### 3.1 壳层接线（responsive_shell.dart）

- [ ] **Step 1: imports 改（删除 foundation 平台 import，新增 4 个模块 import）**

改前：

```dart
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
```

改后：

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, ShortcutActivator;
import 'package:settle_app/app/window_controller.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
```

- [ ] **Step 2: build 中快捷键表改为动作表 + 配置驱动构建（精确改前/改后）**

改前（build L186-207）：

```dart
    // 桌面平台全局快捷键（规格 §5）：N → 收集；Ctrl/Cmd+1..9 → 侧边栏第
    // 1..9 项（收件箱..日志）；Ctrl/Cmd+0 → 回顾。仅桌面（含 Web）包裹
    // Shortcuts/Actions；文本输入焦点时经 [isEnabled] 门控放行按键。
    if (!_shortcutsEnabled) return shell;
    final Map<ShortcutActivator, Intent> shortcuts = {
      const SingleActivator(LogicalKeyboardKey.keyN): const _CollectIntent(),
      // Ctrl/Cmd+0 → 回顾：索引由规范表派生（_digitKeys 9 项之后的首项，
      // 即 _navSpecs[9] = 回顾），与下方 1..9 派生循环共用同一事实源。
      const SingleActivator(LogicalKeyboardKey.digit0, control: true):
          _SwitchViewIntent(_navSpecs[_digitKeys.length].index),
      const SingleActivator(LogicalKeyboardKey.digit0, meta: true):
          _SwitchViewIntent(_navSpecs[_digitKeys.length].index),
    };
    // Ctrl/Cmd+n → 侧边栏第 n 项（_navSpecs 项序即全局索引序，n-1 = 索引）。
    for (var n = 0; n < _digitKeys.length; n++) {
      final index = _navSpecs[n].index;
      shortcuts[SingleActivator(_digitKeys[n], control: true)] =
          _SwitchViewIntent(index);
      shortcuts[SingleActivator(_digitKeys[n], meta: true)] =
          _SwitchViewIntent(index);
    }
    return Shortcuts(
```

改后：

```dart
    // 桌面平台全局快捷键（桌面设置 spec 功能一 §4）：16 动作表 + 用户配置构建
    // （默认绑定与现状逐键一致：N → 收集；Ctrl/Cmd+1..9 → 侧边栏 1..9 项；
    // Ctrl/Cmd+0 → 回顾；Ctrl+Shift+T → 置顶切换）。仅桌面包裹
    // Shortcuts/Actions；文本输入焦点时经 [isEnabled] 门控放行按键。
    final isDesktop = ref.watch(platformBridgeProvider).isDesktop;
    if (!isDesktop) return shell;
    final bindings = ref.watch(shortcutSettingsControllerProvider);
    final Map<ShortcutActivator, Intent> shortcuts = {};
    for (final action in shortcutActions) {
      if (action.layer != ShortcutLayer.shell) continue;
      final intent = _intentFor(action);
      for (final activator in activatorsFor(bindings.bindingFor(action.id))) {
        shortcuts[activator] = intent;
      }
    }
    return Shortcuts(
```

- [ ] **Step 3: Actions map 新增 `_ToggleAlwaysOnTopIntent` 动作（精确改前/改后）**

改前：

```dart
          _SwitchViewIntent: _ShellAction<_SwitchViewIntent>(
            enabled: () => !_isTextEditingFocus(),
            onInvoke: (intent) {
              if (!mounted) return null;
              _switchTo(intent.index);
              return true;
            },
          ),
        },
```

改后：

```dart
          _SwitchViewIntent: _ShellAction<_SwitchViewIntent>(
            enabled: () => !_isTextEditingFocus(),
            onInvoke: (intent) {
              if (!mounted) return null;
              _switchTo(intent.index);
              return true;
            },
          ),
          _ToggleAlwaysOnTopIntent: _ShellAction<_ToggleAlwaysOnTopIntent>(
            enabled: () => !_isTextEditingFocus(),
            onInvoke: (_) {
              if (!mounted) return null;
              ref.read(windowControllerProvider).toggle();
              return true;
            },
          ),
        },
```

- [ ] **Step 4: 删除 `_shortcutsEnabled` getter，原位改放 `_intentFor`（精确改前/改后）**

改前：

```dart
  /// 桌面平台判定（规格 §5）：快捷键仅桌面（含 Web）启用。
  bool get _shortcutsEnabled =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  /// 文本输入焦点判定：primary focus 落在 `EditableText`（TextField 底层）
```

改后：

```dart
  /// 动作 → Intent（spec 功能一 §4）：collect → 收集对话框；toggleAlwaysOnTop →
  /// 置顶切换；nav* → 经 navSpecIndex 构建期解析 `_navSpecs[i].index`
  /// （与现状 Ctrl/0/1..9 派生循环同一事实源，追加式约束不破）。
  Intent _intentFor(ShortcutAction action) {
    switch (action.id) {
      case 'collect':
        return const _CollectIntent();
      case 'toggleAlwaysOnTop':
        return const _ToggleAlwaysOnTopIntent();
      default:
        final i = action.navSpecIndex;
        if (i == null) {
          throw StateError('未知壳层快捷键动作: ${action.id}');
        }
        return _SwitchViewIntent(_navSpecs[i].index);
    }
  }

  /// 文本输入焦点判定：primary focus 落在 `EditableText`（TextField 底层）
```

- [ ] **Step 5: 新增 `_ToggleAlwaysOnTopIntent` Intent 类（`_SwitchViewIntent` 类之后，精确改前/改后）**

改前：

```dart
/// 全局快捷键 Intent：切到指定全局视图索引（Ctrl/Cmd+1..9 → 侧边栏第 n 项；
/// Ctrl/Cmd+0 → 回顾 index 9）。
class _SwitchViewIntent extends Intent {
  const _SwitchViewIntent(this.index);

  /// 目标全局视图索引（0..11，对应 [_navSpecs]）。
  final int index;
}
```

改后：

```dart
/// 全局快捷键 Intent：切到指定全局视图索引（Ctrl/Cmd+1..9 → 侧边栏第 n 项；
/// Ctrl/Cmd+0 → 回顾 index 9）。
class _SwitchViewIntent extends Intent {
  const _SwitchViewIntent(this.index);

  /// 目标全局视图索引（0..11，对应 [_navSpecs]）。
  final int index;
}

/// 全局快捷键 Intent：切换窗口置顶（Ctrl+Shift+T，桌面设置 spec 功能二）。
/// onInvoke 汇于 WindowController.toggle()（设置开关同一写点，唯一状态源）。
class _ToggleAlwaysOnTopIntent extends Intent {
  const _ToggleAlwaysOnTopIntent();
}
```

#### 3.2 列表层接线（task_list_view.dart）

- [ ] **Step 6: imports 改（LogicalKeyboardKey → ShortcutActivator，新增 3 个模块 import）**

改前：

```dart
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/data/providers.dart';
```

改后：

```dart
import 'package:flutter/services.dart' show ShortcutActivator;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/app/glass.dart';
import 'package:settle_app/app/theme.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/core/shortcuts/shortcut_actions.dart';
import 'package:settle_app/core/shortcuts/shortcut_settings_controller.dart';
import 'package:settle_app/data/providers.dart';
```

（`LogicalKeyboardKey` 在该文件仅用于旧快捷键表 L385-391，替换后无残留，故从 import 移除；`ShortcutActivator` 供新表类型标注。）

- [ ] **Step 7: 拖拽形态 `isDesktop` 注释登记「不改」（精确改前/改后）**

改前：

```dart
    // 桌面平台（Windows/macOS/Linux）：行内拖拽手柄（ReorderableDragStartListener
    // 按下即拖，仅包手柄图标，不劫持整行点击/完成钮）；触屏：整行长按延迟拖拽。
    final isDesktop = switch (Theme.of(context).platform) {
```

改后：

```dart
    // 桌面平台（Windows/macOS/Linux）：行内拖拽手柄（ReorderableDragStartListener
    // 按下即拖，仅包手柄图标，不劫持整行点击/完成钮）；触屏：整行长按延迟拖拽。
    // 平台判定收敛（桌面设置 spec）：本判定是主题驱动 UI 形态适配
    // （Theme.of(context).platform），语义独立，不改调 PlatformBridge。
    final isDesktop = switch (Theme.of(context).platform) {
```

- [ ] **Step 8: 快捷键门禁与构建表（精确改前/改后）**

改前：

```dart
    // 列表层快捷键（规格 §5）：仅桌面（isDesktop）且 focusEnabled 时包裹
    // Shortcuts/Actions；J/K 循环移动焦点、Enter 完成焦点任务、Delete 删除
    // 焦点任务（确认对话框）。事件自焦点行冒泡至此层，经 [isEnabled] 门控
    // 确保仅焦点行获焦（且非选择模式）时生效。
    if (!widget.focusEnabled || !isDesktop) return column;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyJ):
            _ListMoveFocusIntent(1),
        SingleActivator(LogicalKeyboardKey.keyK):
            _ListMoveFocusIntent(-1),
        SingleActivator(LogicalKeyboardKey.enter):
            _CompleteFocusedIntent(),
        SingleActivator(LogicalKeyboardKey.delete):
            _DeleteFocusedIntent(),
      },
```

改后：

```dart
    // 列表层快捷键（桌面设置 spec 功能一 §5）：仅桌面且 focusEnabled 时包裹
    // Shortcuts/Actions；默认 J/K 移动焦点、Enter 完成、Delete 删除（用户可
    // 改绑，经配置控制器构建表，与壳层共用 16 动作规范表）。事件自焦点行
    // 冒泡至此层，经 [isEnabled] 门控确保仅焦点行获焦（且非选择模式）时生效。
    final shortcutsEnabled = ref.watch(platformBridgeProvider).isDesktop;
    if (!widget.focusEnabled || !shortcutsEnabled) return column;
    final bindings = ref.watch(shortcutSettingsControllerProvider);
    final shortcuts = <ShortcutActivator, Intent>{
      for (final action in shortcutActions
          .where((a) => a.layer == ShortcutLayer.list))
        for (final activator in activatorsFor(bindings.bindingFor(action.id)))
          activator: switch (action.id) {
            'listMoveUp' => const _ListMoveFocusIntent(1),
            'listMoveDown' => const _ListMoveFocusIntent(-1),
            'listComplete' => const _CompleteFocusedIntent(),
            'listDelete' => const _DeleteFocusedIntent(),
            _ => throw StateError('未知列表层动作: ${action.id}'),
          },
    };
```

- [ ] **Step 9: 回归门禁——既有两个测试文件不改一行，先跑测试确认壳/列表层接线零回归**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter test test/widget/responsive_shell_test.dart test/widget/task_list_view_test.dart 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（默认绑定逐键还原现状 + bridge 与 theme 判定同值 → 既有用例原样通过；若此处红，说明接线偏离契约，停下修复再继续）。

- [ ] **Step 10: 新建 `test/widget/shortcut_wiring_test.dart`（完整文件）**

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/app/responsive_shell.dart';
import 'package:settle_app/app/window_controller.dart';
import 'package:settle_app/core/platform/window_service.dart';
import 'widget_utils.dart';

void main() {
  /// 桌面平台覆盖：widget 测试默认 Android/触屏，快捷键仅桌面启用。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  /// 发送 Ctrl+Shift+key 完整 down/up 序列（避免硬件键盘状态泄漏）。
  Future<void> sendCtrlShiftKey(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('rebind collect→X：按 X 打开收集，按 N 无效', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await env.prefs.setString(
        'shortcut_bindings', jsonEncode({'collect': {'key': 'KeyX'}}));
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(const ResponsiveShell()));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsOneWidget);
    // 取消收集（CollectDialog 取消按钮无 Key，tap 文本）。
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    // 原绑定 N 已迁移 → 无对话框。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collect_dialog_field')), findsNothing);
    await env.db.close();
  });

  testWidgets('Ctrl+Shift+T 切换置顶：fake 记录 + prefs 同步双向', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final fake = FakeWindowService();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(
      const ResponsiveShell(),
      extraOverrides: [windowServiceProvider.overrideWithValue(fake)],
    ));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await sendCtrlShiftKey(tester, LogicalKeyboardKey.keyT);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ResponsiveShell)));
    expect(container.read(windowControllerProvider).alwaysOnTop, true);
    expect(fake.setAlwaysOnTopCalls, [true]);
    expect(env.prefs.getBool(alwaysOnTopPrefsKey), true);
    // 再按 → 还原。
    await sendCtrlShiftKey(tester, LogicalKeyboardKey.keyT);
    expect(container.read(windowControllerProvider).alwaysOnTop, false);
    expect(fake.setAlwaysOnTopCalls, [true, false]);
    await env.db.close();
  });

  testWidgets('文本输入焦点时 Ctrl+Shift+T 不触发置顶（门控保持）', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final fake = FakeWindowService();
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(env.wrap(
      const ResponsiveShell(),
      extraOverrides: [windowServiceProvider.overrideWithValue(fake)],
    ));
    await tester.pump();
    // 切日志页聚焦搜索框（沿用既有用例模式）。
    await tester.tap(find.byKey(const Key('nav_item_8')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('logbook_search')));
    await tester.pump();
    await sendCtrlShiftKey(tester, LogicalKeyboardKey.keyT);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(ResponsiveShell)));
    expect(container.read(windowControllerProvider).alwaysOnTop, false);
    expect(fake.setAlwaysOnTopCalls, isEmpty);
    await env.db.close();
  });
}
```

- [ ] **Step 11: 新建 `test/widget/task_list_wiring_test.dart`（完整文件）**

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'widget_utils.dart';

/// 文件级私有 StreamProvider（仓库测试惯例）：实时喂 TaskListView 的任务。
final _anytimeProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(taskRepositoryProvider).watchAnytime());

/// 测试宿主（与 task_list_view_test 同款）：watch provider 喂数据给
/// TaskListView；焦点快捷键用例依赖 focusEnabled（恒 true）。
class _Host extends ConsumerWidget {
  const _Host(this.provider);

  final StreamProvider<List<Task>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(provider).value ?? const <Task>[];
    return Scaffold(
      body: TaskListView(
        tasks: tasks,
        selectionEnabled: true,
        focusEnabled: true,
      ),
    );
  }
}

void main() {
  /// 桌面平台覆盖：widget 测试默认 Android/触屏，列表快捷键仅桌面启用。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  Future<int> insertTask(TestEnv env, String title, String status) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
          title: title,
          status: status,
          createdAt: 1,
          updatedAt: 1,
        ));
  }

  testWidgets('rebind J→W：按 W 焦点上移生效，按 J 焦点不动', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    await env.prefs.setString(
        'shortcut_bindings', jsonEncode({'listMoveUp': {'key': 'KeyW'}}));
    await insertTask(env, 'Task A', 'next_action');
    await insertTask(env, 'Task B', 'next_action');
    await insertTask(env, 'Task C', 'next_action');
    await tester.pumpWidget(env.wrap(_Host(_anytimeProvider)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    state.focusRow(0);
    await tester.pump();
    expect(state.focusIndex, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.pump();
    expect(state.focusIndex, 1);
    // J 原绑定已迁移 → 焦点不动。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 1);
    await env.db.close();
  });
}
```

- [ ] **Step 12: analyze + 全量测试门禁**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter analyze 2>&1 | Select-Object -Last 3
flutter test 2>&1 | Select-Object -Last 1
```

Expected: analyze 汇总行 0 error 且 0 warning；`flutter test` → `All tests passed!`（217 基线零改动回归 + Task 1-5 新增 + 本 Task 4 个 wiring 测试全绿）。

- [ ] **Step 13: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/app/responsive_shell.dart lib/features/task/task_list_view.dart test/widget/shortcut_wiring_test.dart test/widget/task_list_wiring_test.dart
git commit -m 'feat(shortcuts): 壳层/列表层双接线——配置驱动快捷键表 + 置顶快捷键（含 wiring 测试）'
```

Expected: 提交成功。

### Task 7: 情境视图（ContextTasksPage + 情境页导航接线）——spec 增补（commit 5ee50d2）

**Files:**
- Create: `lib/features/contexts/context_tasks_page.dart`（ContextTasksPage）
- Create: `test/widget/context_tasks_page_test.dart`（5 用例）
- Modify: `lib/features/contexts/contexts_page.dart`（`_ContextTile` 整行点击 → `Navigator.push`）
- Modify: `lib/i18n/l10n/app_en.arb` / `app_zh.arb`（末尾追加 1 key `contextTasksEmpty`）+ 重跑 gen-l10n（3 个生成 dart 文件随本 Task 提交）
- Modify: `test/widget/contexts_page_test.dart`（新增导航用例；既有 2 用例零改动）
- 红线：`lib/data/` 零改动（`watchByContext` 已就绪，spec 增补红线「零 schema 改动」）；情境视图**移动端同样可用**（非桌面专属，仅 focusEnabled 随平台自适应）；不做拖任务入情境 / 情境重排。

> **l10n 落位决策**：`contextTasksEmpty` **不并入 Task 1**（Task 1 已审计定稿 32 key，其 arb diff / 计数 / 提交消息保持不动），改在本 Task 内追加 + 重跑 gen-l10n——本 Task 自包含（1 key 的 arb diff + 生成文件随本 Task 提交）；Task 1 的 `l10n_smoke_test.dart` 只断言其 32 key 各自生成，不枚举全量 key，不因后续新增 key 失效。

- [ ] **Step 1: `app_en.arb` 末尾追加 `contextTasksEmpty`**

改前（文件末尾两行）：

```json
  "guideNote4": "Export a JSON backup anytime."
}
```

改后：

```json
  "guideNote4": "Export a JSON backup anytime.",
  "contextTasksEmpty": "No tasks in this context"
}
```

- [ ] **Step 2: `app_zh.arb` 末尾追加 `contextTasksEmpty`**

改前（文件末尾两行）：

```json
  "guideNote4": "数据可以随时导出 JSON 备份。"
}
```

改后：

```json
  "guideNote4": "数据可以随时导出 JSON 备份。",
  "contextTasksEmpty": "该情境暂无任务"
}
```

- [ ] **Step 3: 重新生成 l10n 并确认 3 个 dart 文件更新**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter gen-l10n
git status --short lib/i18n/l10n
```

Expected: `flutter gen-l10n` 退出码 0；`git status --short` 显示 `app_localizations.dart` / `app_localizations_en.dart` / `app_localizations_zh.dart` 三个生成文件被修改（连同两个 arb）。

- [ ] **Step 4: 新建 `lib/features/contexts/context_tasks_page.dart`（完整文件）**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settle_app/core/enums.dart';
import 'package:settle_app/core/platform/platform_bridge.dart';
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'package:settle_app/i18n/l10n/app_localizations.dart';

/// 情境任务流：文件级 StreamProvider.family（contextId 动态，与各页
/// watchByStatus 同款「仓库只暴露方法、页面转 StreamProvider」约定；
/// family 因 id 而异，`ref.watch(_contextTasksProvider(context.id))` 消费）。
final _contextTasksProvider = StreamProvider.family<List<Task>, int>(
  (ref, contextId) =>
      ref.watch(taskRepositoryProvider).watchByContext(contextId),
);

/// 情境任务页（桌面设置 spec 增补：情境视图，用户确认 2026-11-27 并入本轮）。
/// 情境页 `_ContextTile` 点击 push 进入；AppBar 标题 = 情境名（@ 前缀随用户输入
/// 原样展示，无需额外 title key）；body 复用 TaskListView：
/// - selectionEnabled: true（多选批量）
/// - focusEnabled: 桌面（PlatformBridge.isDesktop → 列表层 J/K/Enter/Delete 复用）
/// - sortMode: standard（统一比较器：优先级 → sortOrder → id）
/// - actions: 仅「完成/删除」子集（跨视图动作如设日期/移动在过滤视角语义弱，裁剪）
/// - reorderEnabled: false（过滤视角，重排与主视图排序冲突）
/// 删除情境仅情境页保留（本页无删除入口，防打开页指向已删情境）；
/// 移动端同样可用（非桌面专属，仅 focusEnabled 随平台自适应）。
class ContextTasksPage extends ConsumerWidget {
  const ContextTasksPage({super.key, required this.context});

  final Context context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = ref.watch(platformBridgeProvider).isDesktop;
    final tasks = ref.watch(_contextTasksProvider(this.context.id));
    return Scaffold(
      appBar: AppBar(title: Text(this.context.name)),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) => rows.isEmpty
            ? Center(
                child: PageRuleHint(
                  icon: Icons.place_outlined,
                  title: l10n.contextTasksEmpty,
                  message: l10n.ruleContextsMessage,
                ),
              )
            : TaskListView(
                tasks: rows,
                selectionEnabled: true,
                focusEnabled: isDesktop,
                sortMode: TaskSortMode.standard,
                actions: const [TaskListAction.complete, TaskListAction.delete],
                reorderEnabled: false,
              ),
      ),
    );
  }
}
```

（空态：title = `contextTasksEmpty`（新 key，spec 增补文案表），message 复用既有 `ruleContextsMessage`（描述「按场景过滤」概念）——仅新增 1 key，AppBar 标题复用情境名本身，无额外 title key。）

- [ ] **Step 5: `contexts_page.dart` 接线（精确改前/改后）**

改前（import 块，L6-8）：

```dart
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';
```

改后：

```dart
import 'package:settle_app/data/providers.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/contexts/context_tasks_page.dart';
import 'package:settle_app/features/guide/page_rule_hint.dart';
```

改前（`_ContextTile.build` 的 ListTile，L73-82）：

```dart
        child: ListTile(
          leading: const Icon(Icons.place),
          title: Text(this.context.name),
          trailing: IconButton(
```

改后：

```dart
        child: ListTile(
          leading: const Icon(Icons.place),
          title: Text(this.context.name),
          // 整行点击 → 情境任务页（spec 增补）。用 ListTile.onTap 而非
          // GestureDetector/InkWell 包裹：ListTile 自带点击水波纹，且 trailing
          // IconButton 持有独立手势识别器，点击按钮时在手势竞技场胜出——
          // 删除按钮与整行点击互不干扰（Flutter 标准模式，无需额外嵌套）。
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ContextTasksPage(context: this.context),
            ),
          ),
          trailing: IconButton(
```

- [ ] **Step 6: 新建 `test/widget/context_tasks_page_test.dart`（完整文件）**

```dart
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/contexts/context_tasks_page.dart';
import 'package:settle_app/features/task/task_list_view.dart';
import 'widget_utils.dart';

void main() {
  /// 取种子情境（@电脑）。
  Future<Context> seedContext(TestEnv env) async =>
      (await env.db.select(env.db.contexts).get()).first;

  Future<int> insertTask(TestEnv env, String title, int contextId) async {
    return env.db.into(env.db.tasks).insert(TasksCompanion.insert(
          title: title,
          status: 'next_action',
          contextId: Value(contextId),
          createdAt: 1,
          updatedAt: 1,
        ));
  }

  /// 桌面平台覆盖：快捷键（focusEnabled）仅桌面启用。
  void useDesktop() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
  }

  testWidgets('任务列表渲染：仅显示该情境的任务', (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    final otherId = await env.db
        .into(env.db.contexts)
        .insert(ContextsCompanion.insert(name: '@工作'));
    await insertTask(env, '情境任务', c.id);
    await insertTask(env, '工作任务', otherId);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    expect(find.text('情境任务'), findsOneWidget);
    expect(find.text('工作任务'), findsNothing);
    await env.db.close();
  });

  testWidgets('空态：情境无任务 → PageRuleHint + contextTasksEmpty',
      (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    expect(find.byKey(const Key('page_rule_hint')), findsOneWidget);
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('批量完成生效：长按 → 完成 → done + 空态', (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    final id = await insertTask(env, '情境任务', c.id);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    await tester.longPress(find.text('情境任务'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_complete')));
    await tester.pumpAndSettle();
    final row = await (env.db.select(env.db.tasks)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.status, 'done');
    expect(find.text('情境任务'), findsNothing);
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('批量删除生效：确认后硬删除', (tester) async {
    final env = await TestEnv.create();
    final c = await seedContext(env);
    final id = await insertTask(env, '情境任务', c.id);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    await tester.longPress(find.text('情境任务'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('task_selection_action_delete')));
    await tester.pumpAndSettle();
    // 确认对话框（TaskListView 内置默认处理，复用 logbook_confirm_delete Key）。
    expect(find.byKey(const Key('logbook_confirm_delete')), findsOneWidget);
    await tester.tap(find.byKey(const Key('logbook_confirm_delete')));
    await tester.pumpAndSettle();
    final rows = await env.db.select(env.db.tasks).get();
    expect(rows.map((r) => r.id), isNot(contains(id)));
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });

  testWidgets('桌面：焦点快捷键可用（J 下移焦点）', (tester) async {
    useDesktop();
    final env = await TestEnv.create();
    final c = await seedContext(env);
    await insertTask(env, 'Task A', c.id);
    await insertTask(env, 'Task B', c.id);
    await tester.pumpWidget(env.wrap(ContextTasksPage(context: c)));
    await tester.pump();
    final state = tester.state<TaskListViewState>(find.byType(TaskListView));
    state.focusRow(0);
    await tester.pump();
    expect(state.focusIndex, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await tester.pump();
    expect(state.focusIndex, 1);
    await env.db.close();
  });
}
```

（注：J 为默认 listMoveUp → `_ListMoveFocusIntent(1)`，焦点 0→1（与 task_list_wiring_test 断言方向一致）；键盘用例须 `useDesktop()` 使 `focusEnabled` 为真，否则无 Shortcuts 子树。断言文案按 en default locale。）

- [ ] **Step 7: `contexts_page_test.dart` 新增导航用例（精确改前/改后）**

改前（import 块，L4-6）：

```dart
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/contexts/contexts_page.dart';
import 'widget_utils.dart';
```

改后：

```dart
import 'package:settle_app/data/tables.dart';
import 'package:settle_app/features/contexts/context_tasks_page.dart';
import 'package:settle_app/features/contexts/contexts_page.dart';
import 'widget_utils.dart';
```

改前（文件末尾，第二个用例收尾 + main 收尾）：

```dart
    final row = await (env.db.select(env.db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
    expect(row.contextId, isNull);
    await env.db.close(); // 关闭 drift 流，避免测试收尾时残留 Timer
  });
}
```

改后：

```dart
    final row = await (env.db.select(env.db.tasks)..where((t) => t.id.equals(taskId))).getSingle();
    expect(row.contextId, isNull);
    await env.db.close(); // 关闭 drift 流，避免测试收尾时残留 Timer
  });

  testWidgets('点击情境 tile → 打开情境任务页（AppBar @情境名）', (tester) async {
    final env = await TestEnv.create();
    await tester.pumpWidget(env.wrap(const ContextsPage()));
    await tester.pump(); // 等待 contexts 流首帧数据
    await tester.tap(find.text('@电脑'));
    await tester.pumpAndSettle();
    expect(find.byType(ContextTasksPage), findsOneWidget);
    // AppBar 标题 = 情境名（@ 前缀随输入原样展示）；情境页 tile 已离屏
    // （offstage）不入匹配，find.descendant 限定 AppBar 内唯一命中。
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('@电脑'),
      ),
      findsOneWidget,
    );
    // 种子情境无任务 → 空态文案（contextTasksEmpty）。
    expect(find.text('No tasks in this context'), findsOneWidget);
    await env.db.close();
  });
}
```

- [ ] **Step 8: 定向测试门禁（本 Task 两个测试文件）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter test test/widget/context_tasks_page_test.dart test/widget/contexts_page_test.dart 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（5 个新页面用例 + 1 个导航用例 + 既有 2 个情境页用例零回归全绿）。

- [ ] **Step 9: analyze + 全量测试门禁**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter analyze 2>&1 | Select-Object -Last 3
flutter test 2>&1 | Select-Object -Last 1
```

Expected: analyze 汇总行 0 error 且 0 warning（仅既有 3 warning / 69 info 基线不动）；`flutter test` → `All tests passed!`（217 基线 + Task 1-6 新增 + 本 Task 6 个新 widget 用例全绿）。

- [ ] **Step 10: 提交**

```powershell
cd D:\Project\gtd-project
git add lib/features/contexts/context_tasks_page.dart lib/features/contexts/contexts_page.dart lib/i18n/l10n/app_en.arb lib/i18n/l10n/app_zh.arb lib/i18n/l10n/app_localizations.dart lib/i18n/l10n/app_localizations_en.dart lib/i18n/l10n/app_localizations_zh.dart test/widget/context_tasks_page_test.dart test/widget/contexts_page_test.dart
git commit -m 'feat(contexts): 情境视图——点击情境进入任务列表（任务列表复用 + 批量完成/删除 + 桌面快捷键 + l10n contextTasksEmpty）'
```

Expected: 提交成功；`git status --short` 无新增修改。

### Task 8: 全量回归 + 验证清单（收官）

**Files:** 无新增改动（纯验证；若验证暴露问题，修复走独立提交）。

- [ ] **Step 1: 全量回归**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter test 2>&1 | Select-Object -Last 1
```

Expected: `All tests passed!`（217 基线 + 新增 7 个测试文件 + settings/l10n/contexts 扩展全部通过；以实际输出计数为准，须全部通过）。

- [ ] **Step 2: 全仓 analyze**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter analyze 2>&1 | Select-Object -Last 3
```

Expected: 汇总行 0 error 且 0 warning（仅允许既有 3 warning / 69 info 基线不动）。

- [ ] **Step 3: Windows 原生构建终门禁（window_manager 原生侧编译/链接验证）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter build windows --release
```

Expected: 构建成功（退出码 0，`build/windows/x64/runner/Release/` 生成可执行文件）。

- [ ] **Step 4: grep 审计——平台判定残留**

```powershell
cd D:\Project\gtd-project
git grep -n "kIsWeb\|defaultTargetPlatform" -- lib test
```

Expected: 仅 `lib/core/platform/` 内命中（platform_bridge.dart 的 detect 工厂 + window_service_desktop.dart 的 `_isSupported` 守卫）——业务代码零平台判定。若 `lib/` 其他目录或 `test/` 有命中，逐条核验（应为注释/文档），残留判定引用需修复。

- [ ] **Step 5: grep 审计——快捷键契约快照（回归锁死的三条映射仍在）**

```powershell
cd D:\Project\gtd-project
git grep -n "KeyN" -- lib/core/shortcuts/shortcut_actions.dart
git grep -n "Digit1, control: true" -- lib/core/shortcuts/shortcut_actions.dart
git grep -n "KeyT, control: true, shift: true" -- lib/core/shortcuts/shortcut_actions.dart
```

Expected: 第一条命中 1 处（collect 默认绑定）；第二条命中 1 处（navInbox）；第三条命中 1 处（toggleAlwaysOnTop）。`_navSpecs` / `_digitKeys` 未被触碰（git status 确认两文件不在改动集）。

- [ ] **Step 6: 可选 Windows 手动冒烟（半自动，非门禁）**

```powershell
$env:PATH = "C:\flutter\bin;$env:PATH"
cd D:\Project\gtd-project
flutter run -d windows
```

人工核对：① 设置页出现「窗口置顶」开关与「快捷键」入口（仅桌面）；② 置顶开关实时置顶、关闭还原；③ 快捷键配置页 16 行 + 键帽（Windows 显 Ctrl、快捷键 Ctrl+Shift+T 显 Ctrl+Shift+T）；④ 点收集行录 Ctrl+X → 键帽变 Ctrl+X，应用内按 Ctrl+X 打开收集、N 失效；⑤ 录键弹窗 Esc 取消、冲突提示（含占用动作名）、纯修饰键提示；⑥ 恢复默认全表回默认；⑦ 重启应用：置顶状态恢复、自定义快捷键生效；⑧ 设置切中文 → 配置页/弹窗双语切换；⑨ 情境页点「@电脑」→ 情境任务页（AppBar 显示 @电脑）、空态显「该情境暂无任务」、有任务时行可批量完成/删除、桌面下 J/K 焦点移动可用，返回情境页删除入口仍在。验证完关闭应用。

- [ ] **Step 7: 工作区与提交记录确认（可选：计划文档勾选回写）**

```powershell
cd D:\Project\gtd-project
git status --short
git log --oneline -8
```

Expected: 工作区干净；提交齐全（feat(l10n) → feat(platform) → feat(shortcuts) ×3 → feat(window) → feat(contexts) 共 7 个功能提交）。若执行器按惯例回写本计划勾选状态，单独提交：

```powershell
git add docs/superpowers/plans/2026-11-27-desktop-settings.md
git commit -m 'docs(plan): 桌面设置增强完成（8 Task 收官）'
```

（此提交为可选收尾，不影响功能。）

---

## 自审记录

- **Spec 覆盖（Files To Change 全清单核对）**：
  - 新增文件 17 个全部落地：`lib/core/platform/platform_bridge.dart`（T2 S3）、`window_service.dart`（T2 S4）、`window_service_desktop.dart`（T2 S5）；`lib/core/shortcuts/shortcut_actions.dart`（T3 S2）、`shortcut_bindings.dart`（T3 S1）、`shortcut_settings_controller.dart`（T3 S3）；`lib/app/window_controller.dart`（T5 S2）；`lib/features/settings/shortcuts/shortcut_settings_page.dart`（T4 S2）、`capture_binding_dialog.dart`（T4 S3）、`shortcut_labels.dart`（T4 S1）；`lib/features/contexts/context_tasks_page.dart`（T7 S4）；测试 7 个：`test/core/shortcut_settings_controller_test.dart`（T3 S4）、`test/core/window_controller_test.dart`（T5 S5）、`test/widget/capture_binding_dialog_test.dart`（T4 S4）、`test/widget/shortcut_settings_page_test.dart`（T4 S5）、`test/widget/shortcut_wiring_test.dart`（T6 S10）、`test/widget/task_list_wiring_test.dart`（T6 S11）、`test/widget/context_tasks_page_test.dart`（T7 S6）。——全覆盖。
  - 修改文件 10 个全部落地：`responsive_shell.dart`（T6 S1-5）、`task_list_view.dart`（T6 S6-8）、`settings_page.dart`（T5 S4）、`main.dart`（T5 S3）、`pubspec.yaml`（T2 S1）、`app_en.arb`/`app_zh.arb`（T1 S3-4 + T7 S1-2）、`widget_utils.dart`（T5 S1）、`settings_page_test.dart`（T5 S6）、`l10n_smoke_test.dart`（T1 S1）、`contexts_page.dart`（T7 S5）、`contexts_page_test.dart`（T7 S7）。——全覆盖。
  - 保留项核对：`responsive_shell_test.dart` 与 `task_list_view_test.dart` **零改动**（T6 S9 门禁用例显式复跑）；task_list_view 拖拽形态 `isDesktop`（theme 驱动）保留 + 注释登记（T6 S7）；`_navSpecs`/`_digitKeys`/启动焦点锚点全部不动（T8 S5 快照）。
  - 增补 Task 覆盖（spec 增补节，commit 5ee50d2）：`ContextTasksPage` 页面参数与 spec 逐条一致（selectionEnabled true / focusEnabled 桌面 / standard 排序 / 完成+删除子集 / 重排关闭 / PageRuleHint + contextTasksEmpty / AppBar 复用情境名 / 无删除入口）；导航用 `ListTile.onTap`（不包裹 InkWell/GestureDetector——trailing IconButton 手势独立，点击按钮时在竞技场胜出，零冲突）；数据源 `StreamProvider.family` 包 `watchByContext`（`lib/data/` 零改动，spec 红线）；情境视图移动端可用（仅 focusEnabled 随平台自适应，不做桌面门控渲染）；既有 2 个情境页用例零改动；`contextTasksEmpty` 落位 Task 7（不并入 Task 1，Task 1 审计内容零改动）；**编号调整**：Task 总数 7→8，原 Task 7（收官验证）顺延为 Task 8，全文引用同步（收官复跑 / 验证清单 / 风险预案快照三处 T7→T8）。
- **依赖顺序修正（与建议 Task 划分一致的三处调整）**：
  1. **设置页双 tile（含置顶开关）整体移入 Task 5**：置顶开关引用 `windowControllerProvider`（Task 5 新建），故 settings_page 全部改动 + settings_page_test 扩展集中在 Task 5；Task 4 只做配置页/录键弹窗/动作名解析（编译依赖仅 l10n + shortcuts 核心，Task 4 结束即全绿）。
  2. **`flutter build windows --release` 门禁在 Task 5 首跑**：window_manager 依赖 Task 2 落地、DesktopWindowService Task 2 创建，但原生构建冒烟放在置顶功能完整（main 接线完成）的 Task 5，Task 8 收官复跑。
  3. **wiring 测试两个文件放 Task 6 末尾**：壳级/列表级接线完成后统一验证，与「既有两个测试文件零改动复跑」门禁同 Task 互为印证。
- **占位符扫描**：无 TBD/TODO/「实现 X」/「…」省略；所有文件改动给出完整新文件内容或精确改前/改后字符串；所有命令给出 Expected 输出。
- **类型/标识一致性**：`WindowService` 接口三方法（ensureInitialized/setAlwaysOnTop）在接口、Noop、Desktop、Fake 四处签名一致；`ShortcutBinding(key/control/meta/shift/alt)` 在模型、动作表、控制器、录键弹窗、键帽五处一致；`activatorsFor`/`actionById`/`logicalKeyForKeyName`/`keyNameOf` 跨文件引用一致；provider 名（platformBridgeProvider/windowServiceProvider/shortcutSettingsControllerProvider/windowControllerProvider）在定义与消费点一致；Key 命名（settings_always_on_top_tile/settings_shortcuts_tile/shortcut_row_*/shortcuts_reset/shortcuts_reset_confirm）测试与实现逐一对上；16 动作 id 在动作表、`_intentFor`、列表层 switch、测试 seed JSON 中全部一致。
- **测试细节修正（自审补强）**：
  1. **shortcut_settings_page_test 缺失 services import 修正**：初稿在文件后补「修正补丁」段落，自审改为直接把 `import 'package:flutter/services.dart';` 写进测试文件 import 块（录键序列需要 LogicalKeyboardKey），并删除补丁说明，避免执行器误读。
  2. **单元测试去除 `bindingFor('unknownId')` 断言**：`bindingFor` 对未知 id 会经 `actionById` 抛 ArgumentError（设计如此），测试只断言「坏条目被忽略」（collect 回默认）+「合法条目保留」（navToday 生效），不再触碰非法 id 查询。
  3. **capture 冲突用例断言改为 prefs 字符串比对**：冲突后 `shortcut_bindings` 应保持 seed 原样，直接比对原 JSON 字符串，避免引入 jsonDecode 二次解析歧义；同时避免直接读控制器（widget 测试容器获取路径复杂），以 prefs 为权威断言。
  4. **置顶开关交互用例用 `pumpAndSettle`**：`toggle()` 内部含两处 await（fake service + prefs），pump 一次不足以保证 prefs 写入完成，统一 `pumpAndSettle`。
  5. **wiring 测试 prefs seed 在 `pumpWidget` 之前**：控制器构造时读 prefs（惰性），seed 必须在首次 pump 前写入——rebind 两个用例均按此顺序。
- **验证清单完整性**：T8 七步（全量 test / analyze / build windows / 平台判定 grep / 快捷键契约快照 / 可选手动冒烟 / 工作区确认），全部给出命令与 Expected；grep 审计模式与 spec 第 5 条一致（kIsWeb/defaultTargetPlatform 仅 lib/core/platform 允许）。
- **风险预案**：window_manager 原生编译失败 → T5 S8 硬门禁 + 单文件回滚面（仅 window_service_desktop.dart + pubspec）；快捷键重构回归 → 默认绑定表逐键对照 + 既有两测试文件零改动复跑（T6 S9）+ T8 S5 快照；坏数据 → fromJson/_load 双防御 + 单元测试覆盖 round-trip 与坏数据；置顶双通道 → toggle() 唯一写点 + window_controller_test 三态锁死 + 凡触发 toggle 的 widget 用例强制 fake override（settings_page_test / shortcut_wiring_test 均显式 override）；平台判定收敛 → bridge 与 theme 同值（既有测试机制不变），拖拽形态保留 theme 判定并注释登记；情境视图 → 数据层零改动（watchByContext 现成）、导航用 ListTile.onTap 避免与删除按钮手势冲突、键盘用例须 useDesktop()（否则 focusEnabled 为假无 Shortcuts 子树）。
