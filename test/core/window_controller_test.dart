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
