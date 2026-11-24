import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtd_app/core/enums.dart';

void main() {
  test('InboxStatus 存储名符合规格 §5.1', () {
    expect(InboxStatus.pending.storage, 'pending');
    expect(InboxStatus.clarified.storage, 'clarified');
    expect(InboxStatus.fromStorage('pending'), InboxStatus.pending);
    expect(InboxStatus.fromStorage('clarified'), InboxStatus.clarified);
  });

  test('TaskStatus 存储名符合规格 §5.1', () {
    expect(TaskStatus.nextAction.storage, 'next_action');
    expect(TaskStatus.waiting.storage, 'waiting');
    expect(TaskStatus.someday.storage, 'someday');
    expect(TaskStatus.done.storage, 'done');
    expect(TaskStatus.fromStorage('next_action'), TaskStatus.nextAction);
    expect(TaskStatus.fromStorage('waiting'), TaskStatus.waiting);
    expect(TaskStatus.fromStorage('someday'), TaskStatus.someday);
    expect(TaskStatus.fromStorage('done'), TaskStatus.done);
  });

  test('ProjectStatus 存储名符合规格 §5.1', () {
    expect(ProjectStatus.active.storage, 'active');
    expect(ProjectStatus.done.storage, 'done');
    expect(ProjectStatus.someday.storage, 'someday');
    expect(ProjectStatus.fromStorage('active'), ProjectStatus.active);
  });

  test('TaskSource 存储名符合规格 §5.1', () {
    expect(TaskSource.text.storage, 'text');
    expect(TaskSource.voice.storage, 'voice');
    expect(TaskSource.share.storage, 'share');
    expect(TaskSource.image.storage, 'image');
    expect(TaskSource.fromStorage('voice'), TaskSource.voice);
  });

  test('Energy/Priority 存储名', () {
    expect(EnergyLevel.low.storage, 'low');
    expect(EnergyLevel.medium.storage, 'medium');
    expect(EnergyLevel.high.storage, 'high');
    expect(PriorityLevel.low.storage, 'low');
    expect(PriorityLevel.high.storage, 'high');
    expect(EnergyLevel.fromStorage('medium'), EnergyLevel.medium);
  });

  test('LocaleSelection 与语言映射', () {
    expect(LocaleSelection.system.locale, isNull);
    expect(LocaleSelection.zh.locale, const Locale('zh'));
    expect(LocaleSelection.en.locale, const Locale('en'));
  });
}
