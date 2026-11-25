// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GTD';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navToday => 'Today';

  @override
  String get navProjects => 'Projects';

  @override
  String get navContexts => 'Contexts';

  @override
  String get navWaiting => 'Waiting';

  @override
  String get navSomeday => 'Someday';

  @override
  String get navUpcoming => 'Upcoming';

  @override
  String get navAnytime => 'Anytime';

  @override
  String get navLogbook => 'Logbook';

  @override
  String get navMore => 'More';

  @override
  String get navGroupTime => 'Time';

  @override
  String get navGroupOrganize => 'Organize';

  @override
  String get navGroupSystem => 'System';

  @override
  String get navReview => 'Review';

  @override
  String get navSettings => 'Settings';

  @override
  String get quickCollectHint => 'Capture something…';

  @override
  String get collectAction => 'Collect';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDeleteTitle => 'Delete?';

  @override
  String get confirmDeleteBody => 'This action cannot be undone.';

  @override
  String get confirmDeleteInbox => 'Permanently delete this inbox item?';

  @override
  String get confirmDeleteProject => 'Delete this project and all its tasks?';

  @override
  String get sourceText => 'Text';

  @override
  String get sourceVoice => 'Voice';

  @override
  String get sourceShare => 'Share';

  @override
  String get sourceImage => 'Image';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusClarified => 'Clarified';

  @override
  String get clarify => 'Clarify';

  @override
  String get clearDate => 'Clear';

  @override
  String get emptyInbox => 'Inbox is empty. Capture your first thought above.';

  @override
  String get emptyTasks => 'Nothing here yet.';

  @override
  String get taskTitle => 'Title';

  @override
  String get taskNotes => 'Notes';

  @override
  String get taskDueDate => 'Due date';

  @override
  String get taskScheduled => 'Scheduled';

  @override
  String get taskEnergy => 'Energy';

  @override
  String get taskPriority => 'Priority';

  @override
  String get taskStatus => 'Status';

  @override
  String get taskWaitingOn => 'Waiting on';

  @override
  String get taskProject => 'Project';

  @override
  String get taskContext => 'Context';

  @override
  String get taskTags => 'Tags';

  @override
  String get noProject => 'No project';

  @override
  String get noContext => 'No context';

  @override
  String get statusNextAction => 'Next action';

  @override
  String get statusWaiting => 'Waiting';

  @override
  String get statusSomeday => 'Someday';

  @override
  String get statusDone => 'Done';

  @override
  String get decisionAction => 'Turn into action';

  @override
  String get decisionProject => 'Turn into project';

  @override
  String get decisionDelete => 'Delete';

  @override
  String get projectName => 'Project name';

  @override
  String get projectGoal => 'Goal';

  @override
  String get newProject => 'New project';

  @override
  String get editProject => 'Edit project';

  @override
  String get editTask => 'Edit task';

  @override
  String get markDone => 'Done';

  @override
  String get reopen => 'Reopen';

  @override
  String get reminder => 'Reminder';

  @override
  String get repeat => 'Repeat';

  @override
  String get repeatDaily => 'Daily';

  @override
  String get repeatEveryN => 'Every N days';

  @override
  String get repeatIntervalInvalid => 'Enter an integer from 1 to 365';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String get repeatNone => 'None';

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get reviewSummary => 'Summary';

  @override
  String get reviewDone => 'Tasks done';

  @override
  String get reviewNew => 'New tasks';

  @override
  String get reviewStalled => 'Stalled';

  @override
  String get saveReview => 'Save review';

  @override
  String get newReview => 'New review';

  @override
  String get language => 'Language';

  @override
  String get langSystem => 'Follow system';

  @override
  String get langZh => '中文';

  @override
  String get langEn => 'English';

  @override
  String get exportBackup => 'Export backup (JSON)';

  @override
  String get importBackup => 'Restore backup (JSON)';

  @override
  String get exportedTo => 'Backup exported';

  @override
  String get importedFrom => 'Backup restored';

  @override
  String get backupInvalid => 'Invalid backup file';

  @override
  String get aiPlaceholder => 'AI model config (available in M2)';

  @override
  String get waitingOnRequired => 'Waiting on is required for waiting tasks.';

  @override
  String get todayTitle => 'Today';

  @override
  String todayOverdue(int count) {
    return '$count overdue';
  }

  @override
  String get todayEmpty => 'Nothing scheduled today.';

  @override
  String get anytimeEmpty => 'No tasks anytime.';

  @override
  String get upcomingEmpty => 'No upcoming tasks.';

  @override
  String get upcomingTomorrow => 'Tomorrow';

  @override
  String get upcomingDayAfter => 'Day after tomorrow';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String upcomingDateHeader(int month, int day, String weekday) {
    return '$month/$day $weekday';
  }

  @override
  String get logbookEmpty => 'No completed tasks yet.';

  @override
  String get logbookSearchEmpty => 'No matching tasks.';

  @override
  String get logbookSearchHint => 'Search';

  @override
  String get logbookDeleteConfirm => 'Delete this task?';

  @override
  String get logbookRestore => 'Restore';

  @override
  String reminderBannerTitle(String title) {
    return 'Reminder: $title';
  }

  @override
  String get reminderOpen => 'Open';

  @override
  String get reminderDismiss => 'OK';
}
