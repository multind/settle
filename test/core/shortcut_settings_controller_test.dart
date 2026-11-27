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
