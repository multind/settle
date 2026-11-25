// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'GTD';

  @override
  String get navInbox => '收件箱';

  @override
  String get navToday => '今日';

  @override
  String get navProjects => '项目';

  @override
  String get navContexts => '情境';

  @override
  String get navWaiting => '等待';

  @override
  String get navSomeday => '将来也许';

  @override
  String get navUpcoming => '即将';

  @override
  String get navAnytime => '随时';

  @override
  String get navLogbook => '日志';

  @override
  String get navMore => '更多';

  @override
  String get navGroupTime => '时间';

  @override
  String get navGroupOrganize => '组织';

  @override
  String get navGroupSystem => '系统';

  @override
  String get navReview => '回顾';

  @override
  String get navSettings => '设置';

  @override
  String get quickCollectHint => '写下你要收集的事情…';

  @override
  String get collectAction => '收集';

  @override
  String get add => '添加';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get confirmDeleteTitle => '确定删除？';

  @override
  String get confirmDeleteBody => '此操作不可撤销。';

  @override
  String get confirmDeleteInbox => '确定永久删除这条收件箱条目？';

  @override
  String get confirmDeleteProject => '确定删除该项目及其下所有任务？';

  @override
  String get sourceText => '文本';

  @override
  String get sourceVoice => '语音';

  @override
  String get sourceShare => '分享';

  @override
  String get sourceImage => '图片';

  @override
  String get statusPending => '待理清';

  @override
  String get statusClarified => '已理清';

  @override
  String get clarify => '理清';

  @override
  String get clearDate => '清除';

  @override
  String get emptyInbox => '收件箱是空的，在上方写下第一条想法。';

  @override
  String get emptyTasks => '这里还没有内容。';

  @override
  String get taskTitle => '标题';

  @override
  String get taskNotes => '备注';

  @override
  String get taskDueDate => '截止日';

  @override
  String get taskScheduled => '计划时间';

  @override
  String get taskEnergy => '精力';

  @override
  String get taskPriority => '优先级';

  @override
  String get taskStatus => '状态';

  @override
  String get taskWaitingOn => '在等谁/等什么';

  @override
  String get taskProject => '所属项目';

  @override
  String get taskContext => '情境';

  @override
  String get taskTags => '标签';

  @override
  String get noProject => '无项目';

  @override
  String get noContext => '无情境';

  @override
  String get statusNextAction => '下一步';

  @override
  String get statusWaiting => '等待';

  @override
  String get statusSomeday => '将来也许';

  @override
  String get statusDone => '完成';

  @override
  String get decisionAction => '转为行动';

  @override
  String get decisionProject => '转为项目';

  @override
  String get decisionDelete => '删除';

  @override
  String get projectName => '项目名称';

  @override
  String get projectGoal => '目标/期望结果';

  @override
  String get newProject => '新建项目';

  @override
  String get editProject => '编辑项目';

  @override
  String get editTask => '编辑任务';

  @override
  String get markDone => '完成';

  @override
  String get reopen => '重新打开';

  @override
  String get reminder => '提醒';

  @override
  String get repeat => '重复';

  @override
  String get repeatDaily => '每日';

  @override
  String get repeatEveryN => '每 N 天';

  @override
  String get repeatIntervalInvalid => '请输入 1-365 之间的整数';

  @override
  String get repeatMonthly => '每月';

  @override
  String get repeatNone => '无';

  @override
  String get repeatWeekly => '每周';

  @override
  String get reviewSummary => '总结';

  @override
  String get reviewDone => '完成任务数';

  @override
  String get reviewNew => '新增任务数';

  @override
  String get reviewStalled => '搁置任务数';

  @override
  String get saveReview => '保存回顾';

  @override
  String get newReview => '新建回顾';

  @override
  String get language => '语言';

  @override
  String get langSystem => '跟随系统';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get exportBackup => '导出备份（JSON）';

  @override
  String get importBackup => '恢复备份（JSON）';

  @override
  String get exportedTo => '备份已导出';

  @override
  String get importedFrom => '备份已恢复';

  @override
  String get backupInvalid => '备份文件无效';

  @override
  String get aiPlaceholder => 'AI 模型配置（M2 启用）';

  @override
  String get waitingOnRequired => '等待任务必须填写等待对象。';

  @override
  String get todayTitle => '今日';

  @override
  String todayOverdue(int count) {
    return '逾期 $count 项';
  }

  @override
  String get todayEmpty => '今日无安排';

  @override
  String get anytimeEmpty => '没有随时可做的任务';

  @override
  String get upcomingEmpty => '没有未来安排';

  @override
  String get upcomingTomorrow => '明天';

  @override
  String get upcomingDayAfter => '后天';

  @override
  String get weekdayMon => '周一';

  @override
  String get weekdayTue => '周二';

  @override
  String get weekdayWed => '周三';

  @override
  String get weekdayThu => '周四';

  @override
  String get weekdayFri => '周五';

  @override
  String get weekdaySat => '周六';

  @override
  String get weekdaySun => '周日';

  @override
  String upcomingDateHeader(int month, int day, String weekday) {
    return '$month月$day日 $weekday';
  }

  @override
  String get logbookEmpty => '暂无完成记录';

  @override
  String get logbookSearchEmpty => '无匹配任务';

  @override
  String get logbookSearchHint => '搜索';

  @override
  String get logbookDeleteConfirm => '确认删除？';

  @override
  String get logbookRestore => '恢复';
}
