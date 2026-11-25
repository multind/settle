import 'package:gtd_app/core/enums.dart';

/// Task 创建/编辑表单的载体。所有字段可空，[title] 必填。
class TaskDraft {
  const TaskDraft({
    required this.title,
    this.notes,
    this.status = TaskStatus.nextAction,
    this.waitingOn,
    this.dueDate,
    this.scheduled,
    this.energy,
    this.priority,
    this.projectId,
    this.contextId,
    this.tagIds = const {},
    this.repeatRule,
    this.reminderAt,
  });

  final String title;
  final String? notes;
  final TaskStatus status;
  final String? waitingOn;
  final DateTime? dueDate;
  final DateTime? scheduled;
  final EnergyLevel? energy;
  final PriorityLevel? priority;
  final int? projectId;
  final int? contextId;
  final Set<int> tagIds;

  /// 重复规则（daily/weekly/monthly/every:N）。
  final String? repeatRule;

  /// 提醒时间（ms epoch 存储时的本地 DateTime）。
  final DateTime? reminderAt;
}
