// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Settle';

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
  String get clarifyOriginal => 'Original note';

  @override
  String get clarifyDetails => 'Task details';

  @override
  String get clarifyCreateAction => 'Create action';

  @override
  String get clarifyCreateProject => 'Create project';

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
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light mode';

  @override
  String get themeDark => 'Dark mode';

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
  String get backupExportFailed =>
      'Could not export the backup. Choose a writable location and try again.';

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
  String todayTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String todayOverdue(int count) {
    return '$count overdue';
  }

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
  String get logbookSearchEmpty => 'No matching tasks.';

  @override
  String get logbookSearchHint => 'Search';

  @override
  String get logbookDeleteConfirm => 'Delete this task?';

  @override
  String get logbookRestore => 'Restore';

  @override
  String taskListSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get exitSelection => 'Exit selection';

  @override
  String get actionComplete => 'Complete';

  @override
  String get actionSetDate => 'Set date';

  @override
  String get actionMove => 'Move';

  @override
  String reminderBannerTitle(String title) {
    return 'Reminder: $title';
  }

  @override
  String get reminderOpen => 'Open';

  @override
  String get reminderDismiss => 'OK';

  @override
  String get navGuide => 'GTD Guide';

  @override
  String get settingsGuide => 'View GTD Guide';

  @override
  String get ruleInboxTitle => 'Collect, don\'t organize';

  @override
  String get ruleInboxMessage =>
      'Start each item with a verb and state the next action.';

  @override
  String get ruleTodayTitle => 'Today is 1-3-5';

  @override
  String get ruleTodayMessage =>
      'Keep 1 big, 3 medium, and 5 small tasks. Add more only after finishing.';

  @override
  String get ruleUpcomingTitle => 'Hard time only';

  @override
  String get ruleUpcomingMessage =>
      'Keep meetings and deadlines here. Drag a task onto a date header to schedule it.';

  @override
  String get ruleAnytimeTitle => 'Do anytime';

  @override
  String get ruleAnytimeMessage =>
      'Tasks you\'ll do soon, without a fixed day, live here.';

  @override
  String get ruleSomedayTitle => 'Maybe later';

  @override
  String get ruleSomedayMessage =>
      'Not now, maybe later — take a look during the weekly review.';

  @override
  String get ruleProjectsTitle => 'Every project needs a next action';

  @override
  String get ruleProjectsMessage =>
      'Give each project a concrete next action and a specific goal.';

  @override
  String get ruleContextsTitle => 'Filter by context';

  @override
  String get ruleContextsMessage =>
      'Filter by place or mood — @work, @home — and do what fits where you are.';

  @override
  String get ruleWaitingTitle => 'Set a follow-up date';

  @override
  String get ruleWaitingMessage =>
      'Every waiting item needs a follow-up date; scan today\'s due follow-ups every day.';

  @override
  String get ruleLogbookTitle => 'Done stays here';

  @override
  String get ruleLogbookMessage =>
      'Completed tasks are kept automatically — count them at your weekly review.';

  @override
  String get ruleReviewTitle => '20 minutes, every week';

  @override
  String get ruleReviewMessage =>
      'Empty the inbox, follow up on waiting, advance projects, activate somedays, and check for hard-time conflicts.';

  @override
  String get onboardingTitle => 'Welcome to Settle';

  @override
  String get ironRule1 => 'Capture everything into the inbox';

  @override
  String get ironRule2 => 'Do it now if it takes two minutes';

  @override
  String get ironRule3 => 'Keep today to 1-3-5';

  @override
  String get dailyAction1 => 'Morning: review Today';

  @override
  String get dailyAction2 =>
      'Evening: clear the inbox, check things off, set tomorrow\'s top task';

  @override
  String get dailyAction3 => 'Sunday: 20-minute review';

  @override
  String get onboardingOpenGuide => 'View the full guide →';

  @override
  String get onboardingClose => 'Close';

  @override
  String get guideSectionLaws => 'Three iron rules';

  @override
  String get guideSectionDaily => 'A daily rhythm';

  @override
  String get guideSectionLists => 'How to use each list';

  @override
  String get guideSectionNotes => 'Notes';

  @override
  String get guideExampleInbox =>
      'e.g. \"Email the client to confirm the quote\"';

  @override
  String get guideExampleToday =>
      'e.g. 1 big \"write the weekly report\" + 3 medium + 5 small';

  @override
  String get guideExampleWaiting =>
      'e.g. \"Waiting on the vendor quote — follow up Friday\"';

  @override
  String get guideExampleProject =>
      'e.g. project \"Moving\" → next action \"call movers for a quote\"';

  @override
  String get guideExampleSomeday => 'e.g. \"learn guitar\", \"visit Iceland\"';

  @override
  String get guideExampleUpcoming =>
      'e.g. Wednesday 14:00 meeting, Friday submission deadline';

  @override
  String get guideNote1 =>
      'Reminders are in-app only — rely on your own attention for what matters.';

  @override
  String get guideNote2 =>
      'Keep important deadlines in your calendar too — belt and braces.';

  @override
  String get guideNote3 =>
      'Never skip the weekly review — it\'s what keeps the system under control.';

  @override
  String get guideNote4 => 'Export a JSON backup anytime.';

  @override
  String get settingsShortcuts => 'Keyboard Shortcuts';

  @override
  String get settingsAlwaysOnTop => 'Always on Top';

  @override
  String get settingsAlwaysOnTopHint => 'Keep the window above others';

  @override
  String get shortcutsTitle => 'Keyboard Shortcuts';

  @override
  String get shortcutsGroupGlobal => 'Global';

  @override
  String get shortcutsGroupList => 'Lists';

  @override
  String get shortcutsReset => 'Reset to Defaults';

  @override
  String get shortcutsResetConfirm => 'Reset all shortcuts to their defaults?';

  @override
  String get actionCollect => 'Collect';

  @override
  String get actionNavInbox => 'Inbox';

  @override
  String get actionNavToday => 'Today';

  @override
  String get actionNavUpcoming => 'Upcoming';

  @override
  String get actionNavAnytime => 'Anytime';

  @override
  String get actionNavSomeday => 'Someday';

  @override
  String get actionNavProjects => 'Projects';

  @override
  String get actionNavContexts => 'Contexts';

  @override
  String get actionNavWaiting => 'Waiting';

  @override
  String get actionNavLogbook => 'Logbook';

  @override
  String get actionNavReview => 'Review';

  @override
  String get actionListUp => 'Focus Up';

  @override
  String get actionListDown => 'Focus Down';

  @override
  String get actionListComplete => 'Complete Focused Task';

  @override
  String get actionListDelete => 'Delete Focused Task';

  @override
  String get actionToggleAlwaysOnTop => 'Toggle Always on Top';

  @override
  String get capturePrompt => 'Press new shortcut…';

  @override
  String get captureEscHint => 'Press Esc to cancel';

  @override
  String captureConflict(String action) {
    return 'This shortcut is already used by $action';
  }

  @override
  String get captureModifiersOnlyHint =>
      'Include at least one non-modifier key';

  @override
  String get keyCtrl => 'Ctrl';

  @override
  String get keyCmd => 'Cmd';

  @override
  String get keyShift => 'Shift';

  @override
  String get keyAlt => 'Alt';

  @override
  String get contextTasksEmpty => 'No tasks in this context';
}
