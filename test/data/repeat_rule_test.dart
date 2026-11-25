import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/models/repeat_rule.dart';

void main() {
  group('RepeatRule.parse', () {
    test('null / 空串 / 未知值 → null', () {
      expect(RepeatRule.parse(null), isNull);
      expect(RepeatRule.parse(''), isNull);
      expect(RepeatRule.parse('unknown'), isNull);
      expect(RepeatRule.parse('every'), isNull);
      expect(RepeatRule.parse('every:'), isNull);
    });

    test('大小写敏感：变体一律 → null', () {
      expect(RepeatRule.parse('EVERY:3'), isNull);
      expect(RepeatRule.parse('Daily'), isNull);
      expect(RepeatRule.parse('Weekly'), isNull);
      expect(RepeatRule.parse('Monthly'), isNull);
    });

    test('every:N 的 N 非法（≤0 / 非数字）→ null', () {
      expect(RepeatRule.parse('every:0'), isNull);
      expect(RepeatRule.parse('every:-5'), isNull);
      expect(RepeatRule.parse('every:abc'), isNull);
      expect(RepeatRule.parse('every:3.5'), isNull);
    });

    test('合法值 → 非 null、isActive 恒 true、storage 原样', () {
      for (final s in ['daily', 'weekly', 'monthly', 'every:1', 'every:3']) {
        final rule = RepeatRule.parse(s);
        expect(rule, isNotNull, reason: s);
        expect(rule!.isActive, isTrue, reason: s);
        expect(rule.storage, s, reason: s);
      }
    });
  });

  group('RepeatRule.nextDate', () {
    test('daily: +1 天（含跨月、跨年边界）', () {
      final rule = RepeatRule.parse('daily')!;
      expect(rule.nextDate(DateTime(2026, 1, 15)), DateTime(2026, 1, 16));
      // 跨月
      expect(rule.nextDate(DateTime(2026, 1, 31)), DateTime(2026, 2, 1));
      // 跨年
      expect(rule.nextDate(DateTime(2025, 12, 31)), DateTime(2026, 1, 1));
    });

    test('weekly: +7 天（保持星期几）', () {
      final rule = RepeatRule.parse('weekly')!;
      final base = DateTime(2026, 1, 5); // 周一
      final next = rule.nextDate(base);
      expect(next, DateTime(2026, 1, 12));
      expect(next.weekday, base.weekday);
    });

    test('monthly: 普通月推进（1/15 → 2/15）', () {
      final rule = RepeatRule.parse('monthly')!;
      expect(rule.nextDate(DateTime(2026, 1, 15)), DateTime(2026, 2, 15));
    });

    test('monthly: 月末钳制（1/31 → 2/28 非闰年）', () {
      final rule = RepeatRule.parse('monthly')!;
      expect(rule.nextDate(DateTime(2023, 1, 31)), DateTime(2023, 2, 28));
    });

    test('monthly: 月末钳制（1/31 → 2/29 闰年）', () {
      final rule = RepeatRule.parse('monthly')!;
      expect(rule.nextDate(DateTime(2024, 1, 31)), DateTime(2024, 2, 29));
    });

    test('monthly: 月末钳制（12/31 → 次年 1/31）', () {
      final rule = RepeatRule.parse('monthly')!;
      expect(rule.nextDate(DateTime(2026, 12, 31)), DateTime(2027, 1, 31));
    });

    test('every:N: N=3 推进；N=1 等同 daily', () {
      final rule3 = RepeatRule.parse('every:3')!;
      expect(rule3.nextDate(DateTime(2026, 1, 15)), DateTime(2026, 1, 18));
      final rule1 = RepeatRule.parse('every:1')!;
      final daily = RepeatRule.parse('daily')!;
      final base = DateTime(2026, 3, 31);
      expect(rule1.nextDate(base), daily.nextDate(base));
    });

    test('nextDate 保留 base 的时分秒', () {
      final base = DateTime(2026, 1, 31, 14, 30, 45, 123);
      for (final s in ['daily', 'weekly', 'monthly', 'every:3']) {
        final next = RepeatRule.parse(s)!.nextDate(base);
        expect(next.hour, base.hour, reason: s);
        expect(next.minute, base.minute, reason: s);
        expect(next.second, base.second, reason: s);
        expect(next.millisecond, base.millisecond, reason: s);
        expect(next.microsecond, base.microsecond, reason: s);
      }
    });
  });
}
