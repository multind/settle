import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/widgets.dart' show ShortcutActivator, SingleActivator;
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
