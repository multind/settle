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
