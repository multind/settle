# 安顿 Settle「桌面设置增强」设计（可配置快捷键 + 窗口置顶 + 平台能力分离架构）

日期：2026-11-27
状态：设计已批准（用户逐节确认 v3 架构修订 + v5 测试清单，本节为落地 spec）
前置：分支 `milestone-1`，HEAD `549fddc`，工作区干净，测试 217/217 全绿，analyze 0 error（3 warning / 69 info 基线）

## Goal（目标）

为安顿 Settle 引入「桌面设置增强」三项能力：① **可配置快捷键**——把现有硬编码的 16 个应用内快捷键（壳层 N 收集 / Ctrl+Cmd+1..9 侧边栏 / Ctrl+Cmd+0 回顾 / 列表层 J/K/Enter/Delete）迁移到一张 16 动作规范表 + 用户可改绑的配置（`lib/core/shortcuts/` 新模块 + 设置页快捷键配置子页 + 录键弹窗），默认绑定与现状逐键一致、零行为回归；② **窗口置顶（always-on-top）**——基于新依赖 window_manager，设置页开关与 `Ctrl+Shift+T` 快捷键双通道实时置顶，启动时恢复上次置顶状态；③ **平台能力分离架构**——新增 `lib/core/platform/` 模块（PlatformBridge 门面 + WindowService 接口/桌面实现/no-op 实现 + Riverpod provider 注入），把现有 3 处内联平台判定收口，业务代码零平台判定，为后续托盘/系统通知/全局热键等平台能力预留统一收口点。持久化仅 2 个纯新增 SharedPreferences key，无数据迁移。

## Non-Goals（非目标）

- **不做全局热键（系统级）**：本轮快捷键仅在应用窗口内生效（Flutter Shortcuts/Actions 机制），不注册系统级热键（留托盘/后台里程碑）。
- **不做托盘 / 系统通知 / 其他窗口能力**：window_manager 仅用于置顶；托盘、系统通知、全局热键、窗口大小记忆等一律不做，且未来各自成 service 收进 `lib/core/platform/`。
- **不迁移数据**：不新增数据表、不改 schema、不改既有 prefs key；`shortcut_bindings` 与 `always_on_top` 均为纯新增 key，删除配置 key 即回默认（无副作用）。
- **不改历史文档**：`docs/superpowers/plans/**`、`docs/superpowers/specs/**` 历史记录保持原样。
- **移动端无新入口**：设置页两个桌面专属 tile 由 bridge.isDesktop 门控不渲染；置顶在移动端自动不可用（no-op service）。
- **不做快捷键「解锁绑」**：每个动作必有绑定（缺省走默认），不提供单动作清除；只有「恢复默认」一键清空。
- **不改导航索引语义 / 不改 `_navSpecs` 结构**：16 动作表的 nav 动作通过 `navSpecIndex`（0..9）在构建期解析 `_navSpecs[i].index`，保持「追加式」约束（与 GTD 指南 spec 同款：插入 index ≤ 9 会平移 Ctrl+0/1..9，禁止）。
- **不引入条件导入 / 平台 stub 分支**（v3 修订，见架构决策）：项目无 web 目标（构建目录仅 android + windows），window_manager 的 Dart 层在 android+windows 均可编译，运行时以守卫兜底。
- **不改主题/视觉体系**：新组件（键帽、配置页、录键弹窗）全部复用现有 token（纯底 + 1px hairline + 圆角 8，零阴影），不新增 token。

## Context（上下文 / 现状盘点）

### 1. 现有 3 处平台判定（本轮收敛对象）

| # | 位置 | 现状代码 | 语义 | 处置 |
|---|---|---|---|---|
| 1 | `lib/app/responsive_shell.dart` L354-358 `_shortcutsEnabled` | `kIsWeb \|\| defaultTargetPlatform == windows/macOS/linux` | 壳层快捷键仅桌面（含 Web）启用 | **改调 PlatformBridge**（bridge 读同一 defaultTargetPlatform + kIsWeb，行为零变化） |
| 2 | `lib/features/task/task_list_view.dart` L309-314 `isDesktop`（`switch (Theme.of(context).platform)`） | windows/macOS/linux → true | **拖拽交互形态适配**（桌面=行内拖拽手柄 / 触屏=长按延迟） | **保留**（主题驱动 UI 适配，独立语义；加注释登记「不改」），快捷键门禁不再复用此变量 |
| 3 | `lib/features/task/task_list_view.dart` L382 快捷键门禁 `!widget.focusEnabled \|\| !isDesktop` | 复用 #2 的 theme 变量 | 列表层 J/K/Enter/Delete 仅桌面启用 | **改调 PlatformBridge.isDesktop** |

收敛后语义不变的原因：`Theme.of(context).platform` 默认值即 `defaultTargetPlatform`，widget 测试的 `debugDefaultTargetPlatformOverride` 同时影响二者——现状测试机制（`useDesktop()` 覆写 + 零覆写即移动端）对两种判定同值，**既有快捷键用例零改动复跑即回归证明**。

### 2. 快捷键硬编码点（responsive_shell.dart 与 task_list_view.dart）

**壳层（`responsive_shell.dart` build L186-252）**：
- `N` → `_CollectIntent()` → 打开 CollectDialog。
- `Ctrl/Cmd+0` → `_SwitchViewIntent(_navSpecs[_digitKeys.length].index)` = `_navSpecs[9]` = 回顾（index 9）。
- `Ctrl/Cmd+1..9` → 循环 `for n in 0..8` 取 `_navSpecs[n].index` → 侧边栏第 n+1 项（收件箱 0 .. 日志 8）。`_digitKeys` 为 9 项 `const List<LogicalKeyboardKey>`（digit1..digit9）。
- 门控：`_ShellAction.isEnabled` → `!_isTextEditingFocus()`（文本输入焦点放行）；外层 `if (!_shortcutsEnabled) return shell`。
- 启动焦点锚点（M-6）：`Focus(autofocus: true, skipTraversal: true)` 包裹 shell，保证启动即按快捷键生效。

**列表层（`task_list_view.dart` build L378-424）**：
- `J` → `_ListMoveFocusIntent(1)`、`K` → `_ListMoveFocusIntent(-1)`（焦点移动）、`Enter` → `_CompleteFocusedIntent()`（完成焦点任务）、`Delete` → `_DeleteFocusedIntent()`（确认后删除）。
- 门控：`_canMoveRowFocus` / `_canOperateRow`（非选择模式 + 行获焦 + 有行/焦点任务）；外层 `if (!widget.focusEnabled || !isDesktop) return column`。
- 现有 `_ListShortcutAction` 与壳层 `_ShellAction` 是同一 isEnabled 门控模式的 6 行重复（M-2 登记，曾留待收尾评估）——本轮**不合并**（保持范围纪律，仍各留原位；两处均改为从 provider 读配置构建表，但 action 门控类不动）。

**文本输入不拦截约束**：壳层与列表层经 isEnabled 门控，焦点落在 `EditableText` 时不触发快捷键——此约束在重构后必须保持（录键弹窗自身在独立 Overlay 路由内获焦，不与壳层 Shortcuts 子树冲突，见功能一）。

### 3. 导航派生关系（`_navSpecs` / `_digitKeys`）

- `_navSpecs` 12 项（index 0..11，含 GTD 指南 index 11）；`_digitKeys` 9 项派生 Ctrl/Cmd+1..9 = `_navSpecs[0..8].index`；Ctrl/Cmd+0 = `_navSpecs[9]` = 回顾。
- **追加式约束**（GTD 指南 spec 已登记）：任何插入 index ≤ 9 的修改都会平移 `_navSpecs[9]` 与 1..9 映射，破坏 Ctrl+0/1..9。本轮动作表不触碰 `_navSpecs`，仅以 `navSpecIndex`（0..9）在构建期解析 `.index`，约束不变。
- `_pages` 为 `late final List<Widget>`（GTD 指南改型后），索引语义 `_navSpecs[i] ↔ _pages[i]`。

### 4. settings_page 结构

`SettingsPage(onOpenGuide: ...)`（ConsumerWidget），现有 tile 顺序：语言（locale_dropdown）→ AI 模型占位（disabled）→ GTD 指南（`settings_guide_tile`）→ 导出（`export_backup_tile`）→ 导入（`import_backup_tile`）。本轮新增两个桌面专属 tile 置于 AI 占位与 GTD 指南之间。

### 5. 依赖与注入现状

- `shared_preferences ^2.3.2` 已用；`main()` 中 `SharedPreferences.getInstance()` 后经 `sharedPreferencesProvider` override 注入（`lib/data/providers.dart`）；测试经 `SharedPreferences.setMockInitialValues({})` mock。
- **无 window_manager**（本轮新增）；`flutter_secure_storage` / `path_provider` / `file_picker` 已存在，本轮不动。
- 语言设置控制器 `SettingsController`（StateNotifier）读 `'locale'` key——本轮快捷键/置顶控制器沿用「构造时读 prefs」模式，但按已批准设计用 **ChangeNotifier**（状态为 map/bool，非单值枚举，见架构决策）。
- 构建平台目录仅 `android/` + `windows/`（无 web/ios/macos/linux 目录）。

## Proposed Architecture（架构决策）

### A. 分层总览与 v3 修订理由

```
lib/core/platform/                        ← 平台能力收口（新）
├── platform_bridge.dart                  ← PlatformBridge 门面（读 defaultTargetPlatform + kIsWeb）+ platformBridgeProvider
├── window_service.dart                   ← WindowService 接口 + NoopWindowService + createWindowService 工厂 + windowServiceProvider
└── window_service_desktop.dart           ← DesktopWindowService（window_manager 封装，全仓唯一 import window_manager 的文件）
lib/core/shortcuts/                       ← 快捷键领域层（新）
├── shortcut_actions.dart                 ← 16 动作规范表（id/labelKey/默认绑定/layer/navSpecIndex）+ activatorsFor 展开
├── shortcut_bindings.dart                ← ShortcutBinding 模型（key+control/meta/shift/alt，JSON 编解码）
└── shortcut_settings_controller.dart     ← ShortcutSettingsController（ChangeNotifier + provider：加载/保存/冲突检测/恢复默认）
lib/app/window_controller.dart            ← WindowController（ChangeNotifier + provider，置顶唯一状态源）+ restoreAlwaysOnTop
lib/features/settings/shortcuts/          ← 设置 UI（新）
├── shortcut_settings_page.dart           ← 快捷键配置页（两组 16 行 + 键帽 + 恢复默认）
├── capture_binding_dialog.dart           ← 录键弹窗（Focus 捕获 + Esc 取消 + 冲突拒绝）
└── shortcut_labels.dart                  ← 16 动作 labelKey → l10n 文本集中 switch（页面与弹窗共用）
```

**v3 修订（不用条件导入 / 不用 stub 分支）的理由**：
1. 项目构建目录仅 android + windows，无 web 目标——`dart:io` 与 window_manager 的 Dart 层在这两个平台均可编译；「按平台条件导入」只解决「某些平台无法编译」的问题，而本项目不存在该问题。
2. 平台差异收敛为**运行时守卫**（impl 内 `_isSupported` 检查 + provider 按 bridge 选择实现），单文件即可表达，比条件导入 + 平台 stub 双文件矩阵更简单、可测试。
3. 未来若真引入 web 目标，再在 `window_service.dart` 的工厂处加条件导入即可，改动面仍是单文件——**v3 决策不阻塞未来**。

### B. 能力判定收敛（3 处平台判定的具体改法）

**① `responsive_shell.dart`**：
- 删除 `_shortcutsEnabled` getter（含 `kIsWeb/defaultTargetPlatform` import）。
- build 中：`final isDesktop = ref.watch(platformBridgeProvider).isDesktop;` → `if (!isDesktop) return shell;`。
- 同步读配置：`final bindings = ref.watch(shortcutSettingsControllerProvider);`（改键即 notify → build 重建 Shortcuts 表，即时生效）。

**② `task_list_view.dart`**：
- `isDesktop`（theme 驱动）**保留且仅用于拖拽形态**（L333 `reorderDraggable && isDesktop`），加注释登记：`// 平台判定收敛（桌面设置 spec）：本判定是主题驱动 UI 形态适配（Theme.of(context).platform），语义独立，不改调 PlatformBridge`。
- 快捷键门禁改为：`final isDesktop = ref.watch(platformBridgeProvider).isDesktop;` + `final bindings = ref.watch(shortcutSettingsControllerProvider);` → `if (!widget.focusEnabled || !isDesktop) return column;`。

**③ 拖拽形态**：不变（见 ② 注释登记）。

### C. PlatformBridge（`lib/core/platform/platform_bridge.dart`）

```dart
/// 平台能力门面：feature/业务代码唯一允许的平台判定入口。
/// 读 defaultTargetPlatform + kIsWeb；经 Riverpod provider 注入，测试可 override。
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

final platformBridgeProvider = Provider<PlatformBridge>((ref) => PlatformBridge.detect());
```

- 字段刻意只暴露本轮需要的能力（isDesktop / isMacOS）；未来托盘/系统通知等按需加字段，**业务代码永远只读 bridge，不直接 import foundation 平台常量**。
- 测试 override：`platformBridgeProvider.overrideWithValue(const PlatformBridge(isDesktop: false, isMacOS: false))`；桌面场景继续用既有 `debugDefaultTargetPlatformOverride`（bridge.detect() 读同一值）。

### D. WindowService（`lib/core/platform/window_service.dart` + `window_service_desktop.dart`）

**接口与工厂**（window_service.dart）：

```dart
/// 窗口能力服务：feature 层只依赖此接口，永不直接接触平台插件。
abstract class WindowService {
  Future<void> ensureInitialized();
  Future<void> setAlwaysOnTop(bool value);
}

/// no-op 空实现：移动端（非桌面）默认注入，置顶自动不可用。
class NoopWindowService implements WindowService {
  @override Future<void> ensureInitialized() async {}
  @override Future<void> setAlwaysOnTop(bool value) async {}
}

/// 唯一实现选择点：main() 与 provider 共用，避免选择逻辑双份。
WindowService createWindowService({required bool isDesktop}) =>
    isDesktop ? DesktopWindowService() : NoopWindowService();

final windowServiceProvider = Provider<WindowService>(
  (ref) => createWindowService(isDesktop: ref.watch(platformBridgeProvider).isDesktop),
);
```

**桌面实现**（window_service_desktop.dart，**全仓唯一 import window_manager 的文件**）：

```dart
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

**window_manager 版本决策**：锁定 **`window_manager: ^0.5.2`**（经典单窗口 API）。理由：① 已批准接口签名（`ensureInitialized()` / `setAlwaysOnTop(bool)`，async）与 0.5.x 经典 API 逐字吻合；② 0.6.0 起该包迁移 nativeapi 架构，经典 API 移入 `package:window_manager/legacy.dart` 且标记 deprecated——用 0.6+ 会引入 `deprecated_member_use` / `deprecated_import` 告警，违反本仓「新增代码 0 warning」纪律；③ 0.5.x 为 1M+ 下载的成熟稳定线；④ 未来升级 nativeapi 时，改动仅限本单文件（接口不变，上层零感知）。

**调用点与时序**（main.dart）：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  final prefs = await SharedPreferences.getInstance();
  final bridge = PlatformBridge.detect();
  final windowService = createWindowService(isDesktop: bridge.isDesktop);
  await windowService.ensureInitialized();          // 桌面初始化原生窗口插件；移动 no-op
  await restoreAlwaysOnTop(prefs, windowService);   // 启动恢复：上次置顶 → 恢复
  runApp(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
      windowServiceProvider.overrideWithValue(windowService),  // 与 main 构造同一实例
    ],
    child: const SettleApp(),
  ));
}
```

### E. WindowController（`lib/app/window_controller.dart`，置顶唯一状态源）

```dart
const String alwaysOnTopPrefsKey = 'always_on_top';

/// 窗口置顶唯一状态源：设置页开关与 toggleAlwaysOnTop 快捷键都走它，实时同步。
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
    await _windowService.setAlwaysOnTop(_alwaysOnTop);  // 移动端 = Noop
    await _prefs.setBool(alwaysOnTopPrefsKey, _alwaysOnTop);
  }
}

/// 启动恢复（main() 调用）：flag 为 true 时置顶；缺省/false 不调用（零动作）。
Future<void> restoreAlwaysOnTop(SharedPreferences prefs, WindowService windowService) async {
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

- **唯一状态源语义**：设置页开关（`ref.watch(windowControllerProvider).alwaysOnTop` / `toggle()`）与快捷键（`_ToggleAlwaysOnTopIntent` → `ref.read(windowControllerProvider).toggle()`）双通道汇于同一 `toggle()`；不出现第二处直接写 `setAlwaysOnTop`/prefs 的代码。
- 启动时序：`main()` 的 `restoreAlwaysOnTop` 与控制器构造读同一 key → 窗口状态与 UI 状态启动即一致。

### F. Riverpod provider 清单与 override 机制

| provider | 类型 | 文件 | 默认构造 | 测试 override |
|---|---|---|---|---|
| `platformBridgeProvider` | `Provider<PlatformBridge>` | platform_bridge.dart | `PlatformBridge.detect()`（读 defaultTargetPlatform + kIsWeb） | `PlatformBridge(isDesktop: false, ...)` 显式控移动端；桌面沿用 `debugDefaultTargetPlatformOverride`（detect 同值） |
| `windowServiceProvider` | `Provider<WindowService>` | window_service.dart | `createWindowService(bridge.isDesktop)`（桌面→Desktop，移动→Noop） | `FakeWindowService`（凡触发 toggle 的用例**必须** override，否则 Desktop impl 会调真实插件抛 MissingPluginException） |
| `shortcutSettingsControllerProvider` | `ChangeNotifierProvider<ShortcutSettingsController>` | shortcut_settings_controller.dart | 读 sharedPreferencesProvider（惰性，pump 时构造） | 默认即可；种子绑定 = pump 前 `env.prefs.setString('shortcut_bindings', jsonEncode(...))` |
| `windowControllerProvider` | `ChangeNotifierProvider<WindowController>` | window_controller.dart | prefs + windowServiceProvider | 默认即可（构造仅读 prefs 不调插件）；交互用例依赖 windowServiceProvider 的 fake |

## 功能一：可配置快捷键（16 动作）

### 1. 动作规范表（`lib/core/shortcuts/shortcut_actions.dart`）

```dart
enum ShortcutLayer { shell, list }   // shell = 壳层（全局组），list = 列表层（列表组）；UI 分组复用此字段

class ShortcutAction {
  const ShortcutAction({
    required this.id,
    required this.labelKey,      // l10n key（actionCollect / actionNav* / ...）
    required this.layer,
    required this.defaultBinding,
    this.navSpecIndex,           // 仅 nav* 动作：_navSpecs 中的位置（0..9），构建期解析 .index
  });
  final String id;
  final String labelKey;
  final ShortcutLayer layer;
  final ShortcutBinding defaultBinding;
  final int? navSpecIndex;       // 非 nav 动作为 null
}
```

**16 动作默认绑定表（逐键还原现状；注册展开列 = 实际注册的快捷键集）**：

| id | labelKey | layer | navSpecIndex | 默认绑定（存储形） | 注册展开（含 control↔meta 派生） |
|---|---|---|---|---|---|
| `collect` | `actionCollect` | shell | – | KeyN（无修饰） | N |
| `navInbox` | `actionNavInbox` | shell | 0 | Digit1 + control | Ctrl+1, Cmd+1 |
| `navToday` | `actionNavToday` | shell | 1 | Digit2 + control | Ctrl+2, Cmd+2 |
| `navUpcoming` | `actionNavUpcoming` | shell | 2 | Digit3 + control | Ctrl+3, Cmd+3 |
| `navAnytime` | `actionNavAnytime` | shell | 3 | Digit4 + control | Ctrl+4, Cmd+4 |
| `navSomeday` | `actionNavSomeday` | shell | 4 | Digit5 + control | Ctrl+5, Cmd+5 |
| `navProjects` | `actionNavProjects` | shell | 5 | Digit6 + control | Ctrl+6, Cmd+6 |
| `navContexts` | `actionNavContexts` | shell | 6 | Digit7 + control | Ctrl+7, Cmd+7 |
| `navWaiting` | `actionNavWaiting` | shell | 7 | Digit8 + control | Ctrl+8, Cmd+8 |
| `navLogbook` | `actionNavLogbook` | shell | 8 | Digit9 + control | Ctrl+9, Cmd+9 |
| `navReview` | `actionNavReview` | shell | 9 | Digit0 + control | Ctrl+0, Cmd+0 |
| `listMoveUp` | `actionListUp` | list | – | KeyJ（无修饰） | J |
| `listMoveDown` | `actionListDown` | list | – | KeyK（无修饰） | K |
| `listComplete` | `actionListComplete` | list | – | Enter（无修饰） | Enter |
| `listDelete` | `actionListDelete` | list | – | Delete（无修饰） | Delete |
| `toggleAlwaysOnTop` | `actionToggleAlwaysOnTop` | shell | – | KeyT + control + shift | Ctrl+Shift+T, Cmd+Shift+T |

- 序列化键名使用 `LogicalKeyboardKey.keyName` 字符串（如 `'KeyN'`、`'Digit2'`、`'Enter'`、`'Delete'`），跨平台稳定且可还原为 LogicalKeyboardKey。
- 默认绑定与现状逐键一致核验：`collect=N` ↔ L191；`navInbox..navLogbook`=Ctrl/Cmd+1..9 ↔ L200-206 派生循环（`_navSpecs[n].index`，n=0..8）；`navReview`=Ctrl/Cmd+0 ↔ L194-197（`_navSpecs[_digitKeys.length]` = `_navSpecs[9]`）；列表四键 ↔ L384-392。
- **navSpecIndex 解析**：壳层构建时 `_SwitchViewIntent(_navSpecs[action.navSpecIndex!].index)`——与现状同一事实源（`_navSpecs`），追加式约束不变（index ≤ 9 禁止插入）。

### 2. ShortcutBinding 模型（`lib/core/shortcuts/shortcut_bindings.dart`）

```dart
class ShortcutBinding {
  const ShortcutBinding({
    required this.key,           // LogicalKeyboardKey.keyName 字符串
    this.control = false, this.meta = false, this.shift = false, this.alt = false,
  });

  /// 规范化标识（键 + 全部修饰符），冲突判定基础。
  String get normalizedId => '$key|${control ? 1 : 0}|${meta ? 1 : 0}|${shift ? 1 : 0}|${alt ? 1 : 0}';

  /// control↔meta 互换变体（派生注册用）。
  ShortcutBinding swapControlMeta();

  Map<String, dynamic> toJson();          // 仅序列化 true 修饰符；key 必存
  factory ShortcutBinding.fromJson(Map<String, dynamic> json);  // 缺省 false；未知 key 名抛 FormatException
}
```

- JSON 形态：`{"key": "KeyX", "control": true, "shift": true}`；纯单键 = `{"key": "KeyN"}`。

### 3. ShortcutSettingsController（`lib/core/shortcuts/shortcut_settings_controller.dart`）

```dart
class ShortcutSettingsController extends ChangeNotifier {
  ShortcutSettingsController(this._prefs) { _load(); }
  final SharedPreferences _prefs;
  Map<String, ShortcutBinding> _custom = {};   // 仅存用户自定义；缺省动作读默认

  ShortcutBinding bindingFor(String actionId) =>
      _custom[actionId] ?? actionById(actionId).defaultBinding;

  /// 保存候选绑定；冲突返回占用动作 id（不保存不通知），成功返回 null。
  String? trySetBinding(String actionId, ShortcutBinding binding);
  Future<void> resetAll();                     // 清空 _custom + 删除 prefs key + notify
}

final shortcutSettingsControllerProvider =
    ChangeNotifierProvider<ShortcutSettingsController>(
  (ref) => ShortcutSettingsController(ref.watch(sharedPreferencesProvider)),
);
```

**关键规则**：

- **持久化**：单 key `shortcut_bindings`，JSON map `{actionId: {key, control, meta, shift, alt}}`（仅含自定义项；空/缺省 = 全默认）。编码失败（非 JSON / 非法 key 名 / 未知 actionId 条目）防御性忽略该项，整串坏 JSON → 空 map 走默认——**坏数据永不崩溃，回退默认即「恢复出厂」**。
- **control↔meta 双注册派生**：`activatorsFor(binding)`（放 shortcut_actions.dart）返回注册键集——自身 + 当且仅当 `control != meta` 时附 `swapControlMeta()` 变体。`collect=N` 不派生（control=meta=false）；`navInbox=Ctrl+1` 派生 Cmd+1（保持现状 macOS Cmd 兼容）；`toggleAlwaysOnTop=Ctrl+Shift+T` 派生 Cmd+Shift+T；`control && meta` 同时为真（罕见）不派生（两修饰已都在）。
- **冲突拒绝（按展开键集）**：候选绑定的 `activatorsFor` 展开集与其余 15 动作当前绑定（自定义或默认）的展开集做相等比对——任一交集即冲突，返回占用动作 id。**必须是展开集比对**：仅比存储形会漏掉「A=Ctrl+T 与 B=Cmd+T」这类经派生后运行时互踩的冲突（A 派生 Cmd+T 撞 B 存储形，反之亦然）。
- **不可解绑**：无单动作清除；`bindingFor` 永远返回有效绑定（自定义或默认）。
- **恢复默认**：`resetAll()` 清空 `_custom` 并删除 `shortcut_bindings` key；`flutter test` 环境亦可直接以空 mock 验证。

### 4. 壳层接线（responsive_shell.dart build）

```dart
final isDesktop = ref.watch(platformBridgeProvider).isDesktop;
final bindings = ref.watch(shortcutSettingsControllerProvider);
if (!isDesktop) return shell;

final Map<ShortcutActivator, Intent> shortcuts = {};
for (final action in shortcutActions) {
  if (action.layer != ShortcutLayer.shell) continue;
  final intent = _intentFor(action);   // collect → _CollectIntent()；toggleAlwaysOnTop → _ToggleAlwaysOnTopIntent()；nav* → _SwitchViewIntent(_navSpecs[action.navSpecIndex!].index)
  for (final activator in activatorsFor(bindings.bindingFor(action.id))) {
    shortcuts[activator] = intent;
  }
}
```

- Actions 表在既有 `_CollectIntent` / `_SwitchViewIntent` 旁新增：
  ```dart
  _ToggleAlwaysOnTopIntent: _ShellAction<_ToggleAlwaysOnTopIntent>(
    enabled: () => !_isTextEditingFocus(),
    onInvoke: (_) {
      if (!mounted) return null;
      ref.read(windowControllerProvider).toggle();
      return true;
    },
  ),
  ```
- **文本输入不拦截约束保持**：门控仍走 `_isTextEditingFocus()`；录键弹窗在独立 Overlay 路由内获焦，其按键事件沿 Overlay/Navigator 祖先链冒泡，**不会**进入壳层 Shortcuts 子树（弹窗内按键不与应用快捷键互扰——与现有收集弹窗同款隔离）。
- **改键即时生效**：`ref.watch(shortcutSettingsControllerProvider)` → 控制器 `notifyListeners()` → build 重建表。
- 启动焦点锚点（M-6 Focus autofocus）、`_digitKeys` 常量、`_navSpecs` 全部不动。

### 5. 列表层接线（task_list_view.dart build）

```dart
// 拖拽形态 isDesktop（theme 驱动）保留，注释登记不改。
final isDesktop = ref.watch(platformBridgeProvider).isDesktop;
final bindings = ref.watch(shortcutSettingsControllerProvider);
if (!widget.focusEnabled || !isDesktop) return column;

final shortcuts = <ShortcutActivator, Intent>{
  for (final action in shortcutActions.where((a) => a.layer == ShortcutLayer.list))
    for (final activator in activatorsFor(bindings.bindingFor(action.id)))
      activator: switch (action.id) {
        'listMoveUp'    => const _ListMoveFocusIntent(1),
        'listMoveDown'  => const _ListMoveFocusIntent(-1),
        'listComplete'  => const _CompleteFocusedIntent(),
        'listDelete'    => const _DeleteFocusedIntent(),
        _ => throw StateError('未知列表层动作: ${action.id}'),
      },
};
```

- 既有 `_canMoveRowFocus` / `_canOperateRow` / `_ListShortcutAction` 门控与 Intent 类全部不动；仅表来源由硬编码 const 改为 provider 构建。

### 6. ShortcutSettingsPage（`lib/features/settings/shortcuts/shortcut_settings_page.dart`）

- 独立 Scaffold + AppBar(title: `l10n.shortcutsTitle`) + actions 区「恢复默认」TextButton（`Key('shortcuts_reset')`）。
- 恢复默认 → 确认对话框（body: `l10n.shortcutsResetConfirm`；按钮：`l10n.cancel` + `l10n.shortcutsReset`，确认按钮 `Key('shortcuts_reset_confirm')`）→ `resetAll()`。
- body 为 ListView：组标题（复用既有 `_groupTitle` 样式：muted 12 w600）`shortcutsGroupGlobal`（12 行：collect + nav×10 + toggleAlwaysOnTop）+ `shortcutsGroupList`（4 行）。
- 每行 `ListTile(key: Key('shortcut_row_${action.id}'))`：title = `actionLabel(l10n, action.labelKey)`；trailing = 键帽（`_Keycap` 小组件：1px hairline 圆角 6 小盒，修饰符符号 + 键名，空格拼接）。
- 键帽渲染规则（`_Keycap` + `_keyLabel(String keyName)` 私有助手）：
  1. 修饰符按固定顺序：主修饰符（control/meta 合并展示）→ Shift → Alt。
  2. 主修饰符展示（`binding.control` / `binding.meta` 合并为单一主修饰符，所见即所得）：`meta && !control`（显式捕获 Cmd/Windows 键）→ `l10n.keyCmd`；`control && !meta`（默认存储形）→ `bridge.isMacOS ? l10n.keyCmd : l10n.keyCtrl`（平台自适应：Windows 显 Ctrl、macOS 显 Cmd）；**control 与 meta 同时为真**（捕获双修饰，罕见）→ 并列展示 keyCtrl + keyCmd。
  3. 键名映射：`Digit0..9` → `'0'..'9'`、`KeyA..KeyZ` → 大写字母、`Enter`/`Delete`/`Space` → 原名，未知 → keyName 原样。
  4. 纯单键绑定 → 仅键名。
- 点击行 → `showDialog` 录键弹窗（见下）。
- 导航方式（决策点）：配置页经 `Navigator.push(MaterialPageRoute(...))` 推入（带返回箭头）。与 GTD 指南不同——指南页是外壳导航目的地（需侧边栏高亮，故用 `_switchTo`）；快捷键配置页是设置子页（模态子配置语义），推入式符合其定位。

### 7. CaptureBindingDialog（`lib/features/settings/shortcuts/capture_binding_dialog.dart`）

- `showDialog` 模态；内容 = 内嵌 `Focus(autofocus: true, onKeyEvent: ...)` 捕获键盘 + 提示文案（`l10n.capturePrompt`「按下新快捷键…」）+ Esc 提示（`l10n.captureEscHint`）+ 状态行（错误/冲突文案，初始为空）。
- 构造参数：`actionId`（配置哪个动作）。
- 按键处理（onKeyDown，忽略 `event.repeat`）：
  - 组合中含 **Escape** → 取消：`Navigator.pop`（状态不变）——Esc 保留为取消键，不可被捕获。
  - 主键（`event.logicalKey`）为修饰键之一（control/meta/shift/alt）且无其他非修饰键 → 显示 `l10n.captureModifiersOnlyHint`，不关闭。
  - 其余（含至少一个非修饰键）→ 组装 `ShortcutBinding`（修饰符取 `HardwareKeyboard.instance.logicalKeysPressed` 中 control/meta/shift/alt 集合）→ `ref.read(shortcutSettingsControllerProvider).trySetBinding(actionId, binding)`：
    - 成功（返回 null）→ `Navigator.pop`；页面经 watch 自动刷新键帽。
    - 冲突（返回占用 actionId）→ 状态行显示 `l10n.captureConflict(actionLabel(l10n, 占用动作.labelKey))`，弹窗不关，清空按键状态等待下一次捕获。
- 遮罩点击（showDialog 默认 barrierDismissible）亦视为取消。

### 8. 动作名集中解析（`lib/features/settings/shortcuts/shortcut_labels.dart`）

`String actionLabel(AppLocalizations l10n, String labelKey)`：16 个 `case 'actionXxx' → l10n.actionXxx` + `default → throw ArgumentError`（与壳层 `_labelOf` 同款模式）；页面行与录键弹窗冲突文案共用。

## 功能二：窗口置顶（always-on-top）

- **依赖**：`window_manager: ^0.5.2`（经典 API；版本理由见架构决策 D）。**仅存于 `window_service_desktop.dart`**；feature 层永不直接 import。
- **唯一状态源**：`WindowController`（见架构决策 E）。设置页开关与 `Ctrl+Shift+T` 快捷键双通道均汇于 `toggle()`，实时同步 UI 与 OS 窗口，无第二写点。
- **启动恢复**：`main()` 中 `restoreAlwaysOnTop(prefs, windowService)`——`always_on_top` 为 true 时 `setAlwaysOnTop(true)`；缺省/false 零动作。与控制器构造读同一 key，启动即一致。
- **平台守卫**：DesktopWindowService 内部 `_isSupported`（windows/macOS/linux）双保险——provider 选择 + 实现内守卫；移动端默认注入 NoopWindowService，置顶自动不可用。
- **设置页入口**：`SwitchListTile(key: Key('settings_always_on_top_tile'), title: l10n.settingsAlwaysOnTop, subtitle: l10n.settingsAlwaysOnTopHint, value: ref.watch(windowControllerProvider).alwaysOnTop, onChanged: (_) => ref.read(windowControllerProvider).toggle())`，仅桌面渲染。

## 设置页 UI（settings_page.dart 变更）

- 新增两桌面专属 tile（`ref.watch(platformBridgeProvider).isDesktop` 门控，非桌面不渲染），置于 AI 占位与 GTD 指南 tile 之间：
  1. 窗口置顶 `SwitchListTile`（`Key('settings_always_on_top_tile')`，leading `Icons.push_pin_outlined`，副标题 `settingsAlwaysOnTopHint`）。
  2. 快捷键 `ListTile`（`Key('settings_shortcuts_tile')`，leading `Icons.keyboard_outlined`，title `settingsShortcuts`）→ `Navigator.push` 到 ShortcutSettingsPage。

## l10n（32 个新 key，zh / en 全量文案草案）

> 注：已批准设计估「约 25」，实际清单求和为 **32**（3+5+16+4+4）——粒度差异见开放问题 1。

### 设置页（3）

| key | zh | en |
|---|---|---|
| `settingsShortcuts` | 快捷键 | Keyboard Shortcuts |
| `settingsAlwaysOnTop` | 窗口置顶 | Always on Top |
| `settingsAlwaysOnTopHint` | 固定到桌面最前置 | Keep the window above others |

### 快捷键配置页（5）

| key | zh | en |
|---|---|---|
| `shortcutsTitle` | 快捷键 | Keyboard Shortcuts |
| `shortcutsGroupGlobal` | 全局 | Global |
| `shortcutsGroupList` | 列表 | Lists |
| `shortcutsReset` | 恢复默认 | Reset to Defaults |
| `shortcutsResetConfirm` | 确定恢复所有快捷键为默认设置？ | Reset all shortcuts to their defaults? |

### 16 动作名（16）

| key | zh | en |
|---|---|---|
| `actionCollect` | 收集 | Collect |
| `actionNavInbox` | 收件箱 | Inbox |
| `actionNavToday` | 今日 | Today |
| `actionNavUpcoming` | 即将 | Upcoming |
| `actionNavAnytime` | 随时 | Anytime |
| `actionNavSomeday` | 将来也许 | Someday |
| `actionNavProjects` | 项目 | Projects |
| `actionNavContexts` | 情境 | Contexts |
| `actionNavWaiting` | 等待 | Waiting |
| `actionNavLogbook` | 日志 | Logbook |
| `actionNavReview` | 回顾 | Review |
| `actionListUp` | 焦点上移 | Focus Up |
| `actionListDown` | 焦点下移 | Focus Down |
| `actionListComplete` | 完成焦点任务 | Complete Focused Task |
| `actionListDelete` | 删除焦点任务 | Delete Focused Task |
| `actionToggleAlwaysOnTop` | 切换窗口置顶 | Toggle Always on Top |

### 录键弹窗（4）

| key | zh | en |
|---|---|---|
| `capturePrompt` | 按下新快捷键… | Press new shortcut… |
| `captureEscHint` | 按 Esc 取消 | Press Esc to cancel |
| `captureConflict` | 该快捷键已被 {action} 占用 | This shortcut is already used by {action} |
| `captureModifiersOnlyHint` | 请至少包含一个非修饰键 | Include at least one non-modifier key |

（`captureConflict` 含 `{action}` 占位符，arb 需声明 `@captureConflict` placeholders，生成 `String captureConflict(String action)`——沿用 `reminderBannerTitle` 同款占位模式。）

### 键帽（4）

| key | zh | en |
|---|---|---|
| `keyCtrl` | Ctrl | Ctrl |
| `keyCmd` | Cmd | Cmd |
| `keyShift` | Shift | Shift |
| `keyAlt` | Alt | Alt |

复用既有 `cancel`（取消 / Cancel）、`save` 不动；恢复默认确认框按钮 = `l10n.cancel` + `l10n.shortcutsReset`（不新增 key）。流程：改 `app_en.arb` + `app_zh.arb` → `flutter gen-l10n` 重新生成 3 个 dart 文件并提交。

## Files To Change（文件改动清单）

### 新增文件

| 文件 | 内容 |
|---|---|
| `lib/core/platform/platform_bridge.dart` | PlatformBridge（isDesktop/isMacOS + detect 工厂）+ platformBridgeProvider |
| `lib/core/platform/window_service.dart` | WindowService 接口 + NoopWindowService + createWindowService 工厂 + windowServiceProvider |
| `lib/core/platform/window_service_desktop.dart` | DesktopWindowService（window_manager 封装，**全仓唯一 import window_manager 的文件**，内部平台守卫） |
| `lib/core/shortcuts/shortcut_actions.dart` | ShortcutAction 规范表（16 动作）+ ShortcutLayer 枚举 + `activatorsFor` 展开 + `actionById` |
| `lib/core/shortcuts/shortcut_bindings.dart` | ShortcutBinding 模型 + toJson/fromJson + normalizedId + swapControlMeta |
| `lib/core/shortcuts/shortcut_settings_controller.dart` | ShortcutSettingsController（ChangeNotifier）+ provider（加载/保存/冲突/恢复默认） |
| `lib/app/window_controller.dart` | WindowController（ChangeNotifier）+ alwaysOnTopPrefsKey + restoreAlwaysOnTop + windowControllerProvider |
| `lib/features/settings/shortcuts/shortcut_settings_page.dart` | 配置页（两组 16 行 + 键帽 + 恢复默认 + `_Keycap`/`_keyLabel` 私有助手） |
| `lib/features/settings/shortcuts/capture_binding_dialog.dart` | 录键弹窗（Focus 捕获/Esc 取消/冲突拒绝/纯修饰键忽略） |
| `lib/features/settings/shortcuts/shortcut_labels.dart` | `actionLabel` 16 动作 labelKey 集中 switch |
| `test/core/shortcut_settings_controller_test.dart` | 控制器单元测试 |
| `test/core/window_controller_test.dart` | WindowController + restoreAlwaysOnTop 单元测试（FakeWindowService） |
| `test/widget/capture_binding_dialog_test.dart` | 录键弹窗测试 |
| `test/widget/shortcut_settings_page_test.dart` | 配置页测试 |
| `test/widget/shortcut_wiring_test.dart` | 壳级接线测试（rebind + toggleAlwaysOnTop） |
| `test/widget/task_list_wiring_test.dart` | 列表级接线测试（rebind J→W） |

### 修改文件

| 文件 | 改动 |
|---|---|
| `lib/app/responsive_shell.dart` | ① 删除 `_shortcutsEnabled` getter 与 foundation 平台 import；② build 改 `ref.watch(platformBridgeProvider).isDesktop` + `ref.watch(shortcutSettingsControllerProvider)` 构建 12 壳层动作 Shortcuts 表（`_intentFor` 解析 navSpecIndex）；③ 新增 `_ToggleAlwaysOnTopIntent` + action（调 `windowControllerProvider.toggle()`）；④ doc 注释同步（快捷键表来源改为 provider 配置） |
| `lib/features/task/task_list_view.dart` | ① 快捷键门禁 `!isDesktop`（theme）→ `ref.watch(platformBridgeProvider).isDesktop` + `ref.watch(shortcutSettingsControllerProvider)` 构建 4 列表动作表；② 拖拽形态 `isDesktop`（theme）保留 + 注释登记「不改」；③ import platform_bridge |
| `lib/features/settings/settings_page.dart` | 新增两桌面 tile（bridge.isDesktop 门控）：窗口置顶 SwitchListTile + 快捷键 ListTile（Navigator.push 配置页） |
| `lib/main.dart` | bridge.detect() + createWindowService + ensureInitialized + restoreAlwaysOnTop + windowServiceProvider override |
| `pubspec.yaml` | `window_manager: ^0.5.2` |
| `lib/i18n/l10n/app_en.arb` / `app_zh.arb` | 新增 32 key（含 captureConflict 占位符声明）；`flutter gen-l10n` 重新生成 3 个 dart 文件 |
| `test/widget/widget_utils.dart` | 新增 `FakeWindowService`（记录 ensureInitialized/setAlwaysOnTop 调用） |
| `test/widget/settings_page_test.dart` | 新增：桌面两 tile 存在 + 置顶开关交互（fake service）+ 快捷键入口导航；移动（bridge override）两 tile 不渲染 |
| `test/widget/l10n_smoke_test.dart` | 新增新 key 双语冒烟 |

**既有测试零改动**（行为回归证明）：`responsive_shell_test.dart`（N / Ctrl+2/5/9/0 / M-6 启动焦点 / 文本焦点门控 / M-3 移动端）、`task_list_view_test.dart`（J/K/Enter/Delete 全套 + 移动端/选择模式门控）——默认绑定逐键还原现状 + bridge 与 theme 判定同值，这些用例原样通过。

## Testing Strategy（测试清单 + 关键断言）

### 1. `shortcut_settings_controller_test.dart`（单元）

- **默认绑定**：`bindingFor('collect')` = KeyN 无修饰；`bindingFor('navInbox')` = Digit1+control；`bindingFor('toggleAlwaysOnTop')` = KeyT+control+shift。
- **加载**：seed JSON → bindingFor 返回存储值。
- **保存**：`trySetBinding('collect', Ctrl+Shift+A)` 返回 null；prefs 的 `shortcut_bindings` JSON 含该项；notifyListeners 触发（listener 计数 +1）。
- **冲突拒绝**：collect=Ctrl+T 后，`trySetBinding('navInbox', Ctrl+T)` 返回 `'collect'`，状态与 JSON 均未变。
- **派生冲突（关键）**：collect=Ctrl+T 后，`trySetBinding('navInbox', Meta+T)` 返回 `'collect'`（展开集碰撞：A 的派生变体 Cmd+T 撞 B 存储形）。
- **恢复默认**：resetAll → 全动作回默认 + prefs key 删除 + notify。
- **JSON 编解码**：round-trip；缺修饰符默认 false；`{'collect': 'notamap'}` / 非法 key 名 / 未知 actionId 条目 → 防御忽略；整串坏 JSON → 空 map 全默认。

### 2. `capture_binding_dialog_test.dart`

- **录键成功**：pump 弹窗（collect）→ sendKey Ctrl+Shift+A（完整 down/up 序列）→ 弹窗关闭 + 控制器 `bindingFor('collect')` = Ctrl+Shift+A。
- **Esc 取消**：sendKey Escape → 弹窗关闭 + 状态不变。
- **含 Esc 组合取消**：Ctrl+Esc → 取消。
- **冲突拒绝**：预置 navInbox=Ctrl+T → 对 collect 录 Ctrl+T → `captureConflict` 文案可见（含「收件箱」），弹窗未关，可继续录其他键。
- **纯修饰键忽略**：只按 Shift → `captureModifiersOnlyHint` 可见，弹窗未关。

### 3. `shortcut_settings_page_test.dart`

- **16 行渲染**：`shortcut_row_collect` .. `shortcut_row_toggleAlwaysOnTop` 全部存在；组标题 `shortcutsGroupGlobal` / `shortcutsGroupList`。
- **键帽**：Windows（useDesktop）下 `shortcut_row_navInbox` 行含文本 'Ctrl' 与 '1'；macOS（`debugDefaultTargetPlatformOverride = TargetPlatform.macOS`）下含 'Cmd' 与 '1'。
- **恢复默认**：预置自定义绑定（如 navInbox→Ctrl+Shift+A）→ 点 `shortcuts_reset` → `shortcutsResetConfirm` 确认框 → 点 `shortcuts_reset_confirm` → 键帽回默认（'Ctrl' + '1'）。
- **录键后更新**：点 `shortcut_row_collect` → 弹窗录 Ctrl+X → 该行键帽变 'Ctrl' + 'X'。

### 4. `shortcut_wiring_test.dart`（壳级，ResponsiveShell 整壳 + desktop override）

- **rebind collect→X**：pump 前 `env.prefs.setString('shortcut_bindings', jsonEncode({'collect': {'key': 'KeyX'}}))` → Tab 建立焦点 → 按 X → CollectDialog 出现；按 N → 无对话框。
- **toggleAlwaysOnTop 快捷键**：override `windowServiceProvider` = FakeWindowService → 按 Ctrl+Shift+T → `windowControllerProvider.alwaysOnTop == true` + fake 记录 `setAlwaysOnTop(true)`；再按 → false + `setAlwaysOnTop(false)` + prefs 更新。
- **文本焦点门控保持**：切日志页聚焦搜索框 → 按 Ctrl+Shift+T → 不触发置顶（沿用既有断言模式）。

### 5. `task_list_wiring_test.dart`（TaskListView + desktop + focusEnabled）

- **rebind J→W**：seed `{'listMoveUp': {'key': 'KeyW'}}` → Tab 聚焦任务行 → 按 W 焦点上移生效；按 J 焦点不动。

### 6. `window_controller_test.dart`（单元，FakeWindowService）

- **初始状态**：prefs 无 `always_on_top` → false；seed true → true。
- **toggle 双向**：toggle() → state true + fake `setAlwaysOnTop(true)` + prefs true；再 toggle → 反之。
- **restoreAlwaysOnTop**：seed true → 调 `setAlwaysOnTop(true)`；缺省 / seed false → 不调用（fake 零调用）。

### 7. `settings_page_test.dart` 扩展

- **桌面两 tile 存在**：useDesktop → `settings_always_on_top_tile` + `settings_shortcuts_tile` 存在。
- **移动不渲染**：override `platformBridgeProvider` = `PlatformBridge(isDesktop: false, isMacOS: false)` → 两 tile 不存在（既有默认 android 用例亦天然覆盖，本用例显式锁 override 路径）。
- **置顶开关交互**：desktop + override windowServiceProvider fake → 点开关 → fake 记录 `setAlwaysOnTop(true)`；再点 → false。
- **快捷键入口**：点 `settings_shortcuts_tile` → ShortcutSettingsPage 可见（AppBar `shortcutsTitle`）。

### 8. `l10n_smoke_test.dart` 扩展

- zh/en 各一轮：`settingsShortcuts`、`settingsAlwaysOnTop`、`actionCollect`、`actionToggleAlwaysOnTop`、`capturePrompt`、`captureConflict('收件箱'/'Inbox')`、`keyCtrl` 取值正确。

### 9. 既有用例零回归

- `responsive_shell_test.dart` 与 `task_list_view_test.dart` 全部原样通过（默认绑定逐键一致 + bridge/theme 同值）——**门禁：这两个文件不改一行**。

## Verification（验证清单）

1. `flutter gen-l10n` 成功（改 arb 后重新生成 3 个 dart 文件入库）。
2. `flutter analyze` **0 error**；新增代码 **0 warning**（既有 3 warning / 69 info 基线不动）。
3. `flutter test` 全绿：217 基线（含上述零改动回归）+ 新增 6 个测试文件 + settings/l10n 扩展。
4. **`flutter build windows --release` 通过**——window_manager 原生侧编译/链接验证，**本轮关键新增门禁**（DesktopWindowService 首次引入原生插件）。
5. grep 审计：`lib/` 与 `test/` 无残留 `kIsWeb` / `defaultTargetPlatform` 直接引用（仅 `lib/core/platform/` 内的 bridge 与窗口服务守卫允许）。
6. 手动 Windows 冒烟（可选）：改键即时生效（N→X）、置顶开关实时置顶、重启恢复置顶、Esc 取消录键、冲突提示（含占用动作名）、恢复默认、中文/英文双语。

## Risks And Mitigations（风险与缓解）

1. **window_manager 集成风险**（原生编译失败 / 运行期 MissingPluginException / 平台差异——0.5.x 经典 API 在 Windows/macOS/Linux 语义差异）。缓解：① 唯一验证目标 Windows——`flutter build windows --release` 硬门禁；macOS/Linux 为守卫支持路径（无 CI，标注「仅代码守卫，无原生验证」）；② window_manager 只存在于 `window_service_desktop.dart` 单文件，任何插件问题回滚面 = 1 文件；③ 实现内 `_isSupported` 守卫 + provider 选择 no-op 兜底，移动端/测试环境绝不触真实插件；④ 版本锁定 `^0.5.2`（0.6+ 经典 API 弃用会产生 analyze 告警，版本决策见架构决策 D）。
2. **快捷键重构回归**（16 动作表替换硬编码 → 键映射/派生遗漏 → 现状行为漂移）。缓解：① 默认绑定表逐键对照现状（spec 表格即契约，含注册展开列）；② **responsive_shell_test 与 task_list_view_test 零改动复跑**作为回归证明；③ nav 动作经 `navSpecIndex` 构建期解析 `_navSpecs[i].index`（同一事实源），追加式约束不破；④ 冲突检测按**展开键集**比对（含派生变体），杜绝「存储形不冲突、运行时互踩」。
3. **持久化格式漂移 / 坏数据**。缓解：纯新增 key 无迁移；`shortcut_bindings` 解码防御（坏条目忽略、整串坏 JSON 回默认）；JSON 编解码单元测试覆盖 round-trip 与坏数据；删除 key 即恢复出厂。
4. **置顶状态源冲突**（设置开关 vs 快捷键双写 / 启动时序不一致）。缓解：`WindowController.toggle()` 唯一写点（无第二处直接调 setAlwaysOnTop/prefs）；启动恢复与控制器构造读同一 key；window_controller_test 锁 toggle 双向 + restore 三态；凡触发 toggle 的 widget 用例强制 override fake service。
5. **平台判定收敛引入行为差异**（`Theme.of(context).platform` vs `defaultTargetPlatform`）。缓解：两者在全部现有测试中同值（ThemeData.platform 默认 = defaultTargetPlatform，`debugDefaultTargetPlatformOverride` 同时影响二者）；拖拽形态判定**保留 theme 驱动不动**，仅快捷键门禁换 bridge；快捷键门禁用例（M-3 移动端 / M-7 选择模式 / 文本焦点门控）零改动复跑。

**回滚**：本功能纯增量——撤销提交即回滚；`window_manager` 依赖移除仅涉 pubspec + window_service_desktop.dart；`shortcut_bindings` / `always_on_top` 残留 key 无副作用（缺省即默认行为）；无数据迁移、无 schema 变更、历史文档不改。

## Decision Summary（决策记录）

- **平台能力收口**：新增 `lib/core/platform/`（platform_bridge + window_service 接口/桌面实现/no-op 实现 + provider 注入）；feature/业务代码零平台判定；window_manager **仅存于 window_service_desktop.dart**；未来托盘/系统通知/全局热键各成 service 收进同目录。
- **v3 修订**：不用条件导入/不用 stub 分支——项目无 web 目标，平台差异以「provider 选择 + 实现内运行时守卫」收敛；未来真有 web 目标时工厂处加条件导入（改动仍单文件）。
- **能力判定收敛**：responsive_shell `_shortcutsEnabled` 与 task_list_view 快捷键门禁 → `PlatformBridge.isDesktop`（行为零变化、既有测试机制不变）；拖拽形态 `Theme.of(context).platform` 保留 + 注释登记「不改」。
- **快捷键**：16 动作规范表（`lib/core/shortcuts/`），默认绑定逐键还原现状（N / Ctrl+1..9 / Ctrl+0 / J/K/Enter/Delete）+ 新增 `toggleAlwaysOnTop=Ctrl+Shift+T`；nav 动作经 `navSpecIndex`（0..9）构建期解析 `_navSpecs[i].index`；control↔meta 双注册派生；冲突按**展开键集**拒绝；不可解绑；「恢复默认」清 key 全表回默认；改键即 notify 重建即时生效。
- **置顶**：`WindowController` 唯一状态源（设置开关 + 快捷键共走 `toggle()`）；`main()` ensureInitialized + `restoreAlwaysOnTop` 启动恢复；`window_manager ^0.5.2`（经典 API，规避 0.6+ legacy 弃用告警；升级路径隔离在单文件）。
- **UI**：设置页两桌面 tile（bridge.isDesktop 门控，置于 AI 占位与 GTD 指南之间）；ShortcutSettingsPage 两组 16 行 + 键帽（Ctrl/Cmd 平台自适应）+ 录键弹窗（Esc 取消、冲突拒绝、纯修饰键忽略）；配置页经 Navigator.push（子配置语义，与指南页外壳切页区分）。
- **持久化**：`shortcut_bindings`（JSON map，仅自定义项）+ `always_on_top`（bool），纯新增 key 无迁移；坏数据防御回默认。
- **l10n**：新增 32 key（zh/en 双语全量草案见正文；超「约 25」估算见开放问题 1）。
- **范围红线**：无全局热键（应用内生效）、无托盘/系统通知、无数据迁移、移动端无新入口且置顶自动不可用、不改导航索引语义、历史文档不改。

## 开放问题（Open Questions）

1. **l10n key 超估算**：已批准设计估「约 25」，清单求和为 32（3+5+16+4+4）——差异源于动作名 16 key + 键帽 4 key 的粒度（与 GTD 指南 spec 的 key 超量先例同型）。文案已全量给出草案，超量属粒度而非冗余；如需精简可合并键帽 key（如 keyCtrl/keyCmd 合一用「Ctrl/Cmd」静态文本），但本轮按全量清单执行。
2. **window_manager 版本**：spec 决策锁定 `^0.5.2`（经典单窗口 API）。0.6.0 起该包迁移 nativeapi 架构、经典 API 移入 legacy.dart 并弃用——若实施时 pub 解析或构建暴露 0.5.x 兼容问题（Flutter 3.50+/Dart 3.14 前瞻），备选方案为 0.7.x + `legacy.dart` 导入 + 单文件 `ignore_for_file: deprecated_member_use`（仍 0 warning，代价是弃用 API 依赖）；两案均不改变 WindowService 接口与上层代码。
3. **键帽对「control 与 meta 同时为真」边界**：已定为并列展示双修饰符（所见即所得）；该边界仅用户主动捕获 Windows 键 + Ctrl 才会出现，无默认绑定触发。
4. **设置页 tile 位置**：两新 tile 置于 AI 占位与 GTD 指南之间为 spec 层布局决策，实施时如需调整属 UI 细节，不影响结构。
5. **macOS/Linux 原生验证缺口**：window_manager 平台守卫覆盖三桌面平台，但仅 Windows 有构建门禁与手动冒烟；macOS/Linux 为守卫代码路径，无 CI 验证（后续里程碑如有 mac 目标再补）。
