import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gtd_app/i18n/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gtd_app/core/enums.dart';
import 'package:gtd_app/core/models/task_draft.dart';
import 'package:gtd_app/data/providers.dart';
import 'package:gtd_app/data/tables.dart';

/// 项目/情境/标签选项流：由仓库暴露的 watchAll() 转为 StreamProvider
/// （与 contexts_page/review_page 同一模式；providers.dart 仅提供仓库本身）。
final _projectsProvider = StreamProvider<List<Project>>(
  (ref) => ref.watch(projectRepositoryProvider).watchAll(),
);
final _contextsProvider = StreamProvider<List<Context>>(
  (ref) => ref.watch(contextRepositoryProvider).watchAll(),
);
final _tagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchAll(),
);

/// Task 全字段表单（理清向导与编辑对话框复用；验收④：截止日/计划/精力/优先级/
/// 等待对象/项目/情境/标签）。
class TaskFormFields extends ConsumerStatefulWidget {
  const TaskFormFields({
    super.key,
    this.initial,
    this.initialTagIds = const {},
    this.allowStatusChange = true,
  });

  /// 编辑既有任务时的初始值；创建时传 null。
  final TaskDraft? initial;
  final Set<int> initialTagIds;

  /// 编辑场景禁止改状态（避免误把已完成任务改回等待）。
  final bool allowStatusChange;

  @override
  ConsumerState<TaskFormFields> createState() => TaskFormFieldsState();
}

class TaskFormFieldsState extends ConsumerState<TaskFormFields> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late final TextEditingController _waitingOn;
  late TaskStatus _status;
  DateTime? _dueDate;
  DateTime? _scheduled;
  DateTime? _reminderAt;
  String? _repeatKind;
  late final TextEditingController _repeatInterval;
  EnergyLevel? _energy;
  PriorityLevel? _priority;
  int? _projectId;
  int? _contextId;
  final Set<int> _tagIds = {};

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _title = TextEditingController(text: d?.title ?? '');
    _notes = TextEditingController(text: d?.notes ?? '');
    _waitingOn = TextEditingController(text: d?.waitingOn ?? '');
    _repeatInterval = TextEditingController();
    _status = d?.status ?? TaskStatus.nextAction;
    _dueDate = d?.dueDate;
    _scheduled = d?.scheduled;
    _reminderAt = d?.reminderAt;
    _energy = d?.energy;
    _priority = d?.priority;
    _projectId = d?.projectId;
    _contextId = d?.contextId;
    _repeatKind = _decodeRepeatKind(d?.repeatRule, _repeatInterval);
    _tagIds.addAll(widget.initialTagIds);
  }

  /// 反解析存储 repeatRule 回下拉态：null→无；daily/weekly/monthly→对应项；
  /// every:N→'every' 并把 N 值回填进 [interval] 控制器。
  /// N 非法（非数字 / 超出 1-365 表单有效域）时与 [RepeatRule.parse] 一致视为
  /// 「不重复」→ 回退 null（下拉显示「无」），避免校验器永久拦截保存。
  String? _decodeRepeatKind(String? rule, TextEditingController interval) {
    switch (rule) {
      case 'daily':
      case 'weekly':
      case 'monthly':
        return rule;
      default:
        if (rule != null && rule.startsWith('every:')) {
          final n = int.tryParse(rule.substring('every:'.length));
          if (n != null && n >= 1 && n <= 365) {
            interval.text = '$n';
            return 'every';
          }
        }
        return null;
    }
  }

  @override
  void didUpdateWidget(TaskFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.initialTagIds, widget.initialTagIds)) {
      _tagIds
        ..clear()
        ..addAll(widget.initialTagIds);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _waitingOn.dispose();
    _repeatInterval.dispose();
    super.dispose();
  }

  /// 校验并返回草稿；校验失败返回 null。
  TaskDraft? validate() {
    if (!_formKey.currentState!.validate()) return null;
    return TaskDraft(
      title: _title.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      status: _status,
      waitingOn: _status == TaskStatus.waiting ? _waitingOn.text.trim() : null,
      dueDate: _dueDate,
      scheduled: _scheduled,
      repeatRule: _computedRepeatRule(),
      reminderAt: _reminderAt,
      energy: _energy,
      priority: _priority,
      projectId: _projectId,
      contextId: _contextId,
      tagIds: Set.of(_tagIds),
    );
  }

  /// 下拉态 → 存储值：daily/weekly/monthly 原样；every:N 合成；无 → null。
  String? _computedRepeatRule() {
    switch (_repeatKind) {
      case 'daily':
      case 'weekly':
      case 'monthly':
        return _repeatKind;
      case 'every':
        // 校验器已拦非法 N（1-365），此处防御性兜底。
        final n = int.tryParse(_repeatInterval.text.trim());
        return n == null ? null : 'every:$n';
      default:
        return null;
    }
  }

  /// 链式选择日期+时间：先 showDatePicker 再 showTimePicker。
  /// 无既有值时时间默认 09:00；有既有值时保留原时分。
  Future<void> _pickDateTime(DateTime? current, void Function(DateTime) apply) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    apply(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  /// 展示 `yyyy-MM-dd HH:mm`（手工补零，不依赖 intl DateFormat）。
  String _fmtDateTime(DateTime d) =>
      '${d.year}-${_p2(d.month)}-${_p2(d.day)} ${_p2(d.hour)}:${_p2(d.minute)}';

  String _p2(int n) => n.toString().padLeft(2, '0');

  Widget _dateTimeTile({
    Key? tileKey,
    required String label,
    required DateTime? value,
    required Key clearKey,
    required VoidCallback onClear,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: tileKey,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(label),
      trailing: value == null
          ? const Text('-')
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmtDateTime(value)),
                IconButton(
                  key: clearKey,
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: AppLocalizations.of(context)!.clearDate,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onClear,
                ),
              ],
            ),
      onTap: onTap,
    );
  }

  String _statusLabel(AppLocalizations l10n, TaskStatus s) => switch (s) {
        TaskStatus.nextAction => l10n.statusNextAction,
        TaskStatus.waiting => l10n.statusWaiting,
        TaskStatus.someday => l10n.statusSomeday,
        TaskStatus.done => l10n.statusDone,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.watch(_projectsProvider);
    final contexts = ref.watch(_contextsProvider);
    final tags = ref.watch(_tagsProvider);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('task_title_field'),
            controller: _title,
            decoration: InputDecoration(labelText: l10n.taskTitle),
            validator: (v) => (v == null || v.trim().isEmpty) ? l10n.taskTitle : null,
          ),
          if (widget.allowStatusChange) ...[
            const SizedBox(height: 4),
            DropdownButtonFormField<TaskStatus>(
              key: const Key('task_status_field'),
              initialValue: _status,
              decoration: InputDecoration(labelText: l10n.taskStatus),
              items: [
                for (final s in TaskStatus.values)
                  DropdownMenuItem<TaskStatus>(value: s, child: Text(_statusLabel(l10n, s))),
              ],
              onChanged: (v) => setState(() => _status = v ?? TaskStatus.nextAction),
            ),
          ],
          if (_status == TaskStatus.waiting) ...[
            const SizedBox(height: 4),
            TextFormField(
              key: const Key('task_waiting_on_field'),
              controller: _waitingOn,
              decoration: InputDecoration(labelText: l10n.taskWaitingOn),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.waitingOnRequired : null,
            ),
          ],
          const SizedBox(height: 4),
          TextFormField(
            key: const Key('task_notes_field'),
            controller: _notes,
            decoration: InputDecoration(labelText: l10n.taskNotes),
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<EnergyLevel?>(
                  key: const Key('task_energy_field'),
                  initialValue: _energy,
                  decoration: InputDecoration(labelText: l10n.taskEnergy),
                  items: [
                    const DropdownMenuItem<EnergyLevel?>(value: null, child: Text('-')),
                    for (final e in EnergyLevel.values)
                      DropdownMenuItem<EnergyLevel?>(value: e, child: Text(e.storage)),
                  ],
                  onChanged: (v) => setState(() => _energy = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PriorityLevel?>(
                  key: const Key('task_priority_field'),
                  initialValue: _priority,
                  decoration: InputDecoration(labelText: l10n.taskPriority),
                  items: [
                    const DropdownMenuItem<PriorityLevel?>(value: null, child: Text('-')),
                    for (final p in PriorityLevel.values)
                      DropdownMenuItem<PriorityLevel?>(value: p, child: Text(p.storage)),
                  ],
                  onChanged: (v) => setState(() => _priority = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dateTimeTile(
                  label: l10n.taskDueDate,
                  value: _dueDate,
                  clearKey: const Key('clear_due'),
                  onClear: () => setState(() => _dueDate = null),
                  onTap: () =>
                      _pickDateTime(_dueDate, (v) => setState(() => _dueDate = v)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _dateTimeTile(
                  label: l10n.taskScheduled,
                  value: _scheduled,
                  clearKey: const Key('clear_scheduled'),
                  onClear: () => setState(() => _scheduled = null),
                  onTap: () =>
                      _pickDateTime(_scheduled, (v) => setState(() => _scheduled = v)),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _dateTimeTile(
                  tileKey: const Key('task_reminder_field'),
                  label: l10n.reminder,
                  value: _reminderAt,
                  clearKey: const Key('clear_reminder'),
                  onClear: () => setState(() => _reminderAt = null),
                  onTap: () =>
                      _pickDateTime(_reminderAt, (v) => setState(() => _reminderAt = v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String?>(
            key: const Key('task_repeat_field'),
            initialValue: _repeatKind,
            decoration: InputDecoration(labelText: l10n.repeat),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l10n.repeatNone)),
              DropdownMenuItem<String?>(value: 'daily', child: Text(l10n.repeatDaily)),
              DropdownMenuItem<String?>(value: 'weekly', child: Text(l10n.repeatWeekly)),
              DropdownMenuItem<String?>(value: 'monthly', child: Text(l10n.repeatMonthly)),
              DropdownMenuItem<String?>(value: 'every', child: Text(l10n.repeatEveryN)),
            ],
            onChanged: (v) => setState(() => _repeatKind = v),
          ),
          if (_repeatKind == 'every') ...[
            const SizedBox(height: 4),
            TextFormField(
              key: const Key('task_repeat_interval'),
              controller: _repeatInterval,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.repeatEveryN),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 1 || n > 365) return l10n.repeatIntervalInvalid;
                return null;
              },
            ),
          ],
          const SizedBox(height: 4),
          projects.when(
            data: (list) => DropdownButtonFormField<int?>(
              key: const Key('task_project_field'),
              initialValue: _projectId,
              decoration: InputDecoration(labelText: l10n.taskProject),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('—')),
                for (final p in list) DropdownMenuItem<int?>(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _projectId = v),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          contexts.when(
            data: (list) => DropdownButtonFormField<int?>(
              key: const Key('task_context_field'),
              initialValue: _contextId,
              decoration: InputDecoration(labelText: l10n.taskContext),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('—')),
                for (final c in list) DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _contextId = v),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          tags.when(
            data: (list) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in list)
                  FilterChip(
                    key: Key('tag_chip_${t.id}'),
                    label: Text(t.name),
                    selected: _tagIds.contains(t.id),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _tagIds.add(t.id);
                      } else {
                        _tagIds.remove(t.id);
                      }
                    }),
                  ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
