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
