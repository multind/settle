import 'window_service.dart';

/// no-op 空实现：移动端（非桌面）默认注入，置顶自动不可用。
class NoopWindowService implements WindowService {
  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> setAlwaysOnTop(bool value) async {}
}
