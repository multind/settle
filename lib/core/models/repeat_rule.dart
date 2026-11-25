/// 重复规则模型（spec §4.3）。
///
/// 存储格式为简单字符串，直接落库于 `tasks.repeatRule`：
///
/// | 存储值 | 推进规则 |
/// |---|---|
/// | `daily` | +1 天 |
/// | `weekly` | +7 天（保持星期几） |
/// | `monthly` | +1 月，月末钳制（1/31 → 2/28 或 2/29） |
/// | `every:N` | +N 天（N ≥ 1，自定义间隔） |
///
/// 无效值（null / 空串 / 未知值 / N 非法）一律视为「不重复」：
/// [parse] 返回 null。
///
/// 不可变：所有字段为 final，构造后不可修改。
class RepeatRule {
  const RepeatRule._(this.storage, this._kind, this._days);

  /// 规范存储字符串（与 spec §4.3 格式一致）。
  final String storage;

  final _RepeatKind _kind;

  /// `every:N` 的间隔天数；仅当 [_kind] 为 custom 时有效。
  final int _days;

  /// 解析存储字符串；null / 空 / 未知 / `every:N` 的 N 非法 → null。
  ///
  /// 大小写敏感：`EVERY:3`、`Daily` 等变体视为未知值。
  static RepeatRule? parse(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value) {
      case 'daily':
        return const RepeatRule._('daily', _RepeatKind.daily, 0);
      case 'weekly':
        return const RepeatRule._('weekly', _RepeatKind.weekly, 0);
      case 'monthly':
        return const RepeatRule._('monthly', _RepeatKind.monthly, 0);
    }
    if (value.startsWith('every:')) {
      final n = int.tryParse(value.substring('every:'.length));
      if (n == null || n < 1) return null;
      return RepeatRule._('every:$n', _RepeatKind.custom, n);
    }
    return null;
  }

  /// parse 成功即 true；本模型构造后恒为 true，供调用方判断是否重复。
  bool get isActive => true;

  /// 按规则推进一次：返回下一次的日期，并保留 [base] 的时分秒与毫秒/微秒。
  DateTime nextDate(DateTime base) => switch (_kind) {
        _RepeatKind.daily => _shiftDays(base, 1),
        _RepeatKind.weekly => _shiftDays(base, 7),
        _RepeatKind.monthly => _nextMonthClamped(base),
        _RepeatKind.custom => _shiftDays(base, _days),
      };

  DateTime _shiftDays(DateTime base, int days) => DateTime(
        base.year,
        base.month,
        base.day + days,
        base.hour,
        base.minute,
        base.second,
        base.millisecond,
        base.microsecond,
      );

  /// +1 月并做月末钳制：目标月最后一天 = 下下月的「0 日」的 day。
  DateTime _nextMonthClamped(DateTime base) {
    final targetYear = base.month == 12 ? base.year + 1 : base.year;
    final targetMonth = base.month == 12 ? 1 : base.month + 1;
    final lastDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final day = base.day > lastDay ? lastDay : base.day;
    return DateTime(
      targetYear,
      targetMonth,
      day,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
      base.microsecond,
    );
  }
}

enum _RepeatKind { daily, weekly, monthly, custom }
