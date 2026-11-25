import 'dart:async';

import 'package:gtd_app/data/repositories/task_repository.dart';
import 'package:gtd_app/data/tables.dart';

/// 应用内到点提醒服务（主规格 §2 非目标：不做系统级通知）。
///
/// 30s 轮询 [TaskRepository.dueReminders]，取「上一轮时间 < reminderAt <= now
/// 且未完成」的任务；同一会话同一任务只提醒一次（内存 `Set<int> notifiedIds`）。
/// 新命中经 [reminders] 广播，供 UI（ResponsiveShell）弹 Banner。
///
/// 时钟与 [TaskRepository] 一致：构造注入可选 `now`（测试注入固定时刻），
/// 轮询边界用注入时钟；缺省 `DateTime.now`。
///
/// 生命周期幂等契约：`start()` 可重复调用（已启动/已 dispose 均 no-op）；
/// `dispose()` 可重复调用（仅首次生效，二次调用 no-op，不会对已关闭的
/// controller 重复 close）。dispose 后再 start 不会重建轮询。
class ReminderService {
  ReminderService(
    this._repo, {
    DateTime Function()? now,
    this.pollInterval = const Duration(seconds: 30),
  }) : _now = now ?? DateTime.now;

  /// 首轮窗口下界：0（1970 起点）。应用打开后第一轮即把「已过期的提醒」补上，
  /// 之后每轮为增量窗口（`上一轮时间 < reminderAt <= now`）。
  static const int _initialSinceMs = 0;

  final TaskRepository _repo;
  final DateTime Function() _now;
  final Duration pollInterval;

  /// 本会话已通知过的任务 id（同会话同任务只提醒一次）。
  final Set<int> _notifiedIds = {};

  /// 上一轮轮询时刻（ms epoch）；首轮为 [_initialSinceMs]。
  int _lastPollMs = _initialSinceMs;

  Timer? _timer;
  final StreamController<List<Task>> _controller =
      StreamController<List<Task>>.broadcast();

  /// 已释放标记：dispose 后 start/再次 dispose 均 no-op（防跨生命周期复用）。
  bool _disposed = false;

  /// 新命中任务流（每轮有新命中时 emit 一次 List<Task>）。
  Stream<List<Task>> get reminders => _controller.stream;

  /// 启动轮询（幂等：已启动则忽略；已 dispose 则 no-op）。
  void start() {
    if (_disposed) return;
    _timer ??= Timer.periodic(pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    final now = _now().millisecondsSinceEpoch;
    List<Task> due;
    try {
      due = await _repo.dueReminders(since: _lastPollMs, now: now);
    } catch (_) {
      // 单轮失败不中断后续轮询（dispose 竞态/瞬时错误均跳过本轮）。
      return;
    }
    final fresh = due.where((t) => !_notifiedIds.contains(t.id)).toList();
    if (fresh.isNotEmpty && !_controller.isClosed) {
      _notifiedIds.addAll(fresh.map((t) => t.id));
      _controller.add(fresh);
    }
    _lastPollMs = now;
  }

  /// 取消轮询并释放流（幂等：重复调用 no-op）。
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
