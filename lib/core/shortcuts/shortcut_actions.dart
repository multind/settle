import 'package:flutter/widgets.dart' show ShortcutActivator, SingleActivator;
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
