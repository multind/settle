import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get appTitle;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// No description provided for @navContexts.
  ///
  /// In en, this message translates to:
  /// **'Contexts'**
  String get navContexts;

  /// No description provided for @navWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get navWaiting;

  /// No description provided for @navSomeday.
  ///
  /// In en, this message translates to:
  /// **'Someday'**
  String get navSomeday;

  /// No description provided for @navUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get navUpcoming;

  /// No description provided for @navAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get navAnytime;

  /// No description provided for @navLogbook.
  ///
  /// In en, this message translates to:
  /// **'Logbook'**
  String get navLogbook;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navGroupTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get navGroupTime;

  /// No description provided for @navGroupOrganize.
  ///
  /// In en, this message translates to:
  /// **'Organize'**
  String get navGroupOrganize;

  /// No description provided for @navGroupSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get navGroupSystem;

  /// No description provided for @navReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get navReview;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @quickCollectHint.
  ///
  /// In en, this message translates to:
  /// **'Capture something…'**
  String get quickCollectHint;

  /// No description provided for @collectAction.
  ///
  /// In en, this message translates to:
  /// **'Collect'**
  String get collectAction;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get confirmDeleteBody;

  /// No description provided for @confirmDeleteInbox.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this inbox item?'**
  String get confirmDeleteInbox;

  /// No description provided for @confirmDeleteProject.
  ///
  /// In en, this message translates to:
  /// **'Delete this project and all its tasks?'**
  String get confirmDeleteProject;

  /// No description provided for @sourceText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get sourceText;

  /// No description provided for @sourceVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get sourceVoice;

  /// No description provided for @sourceShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get sourceShare;

  /// No description provided for @sourceImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get sourceImage;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusClarified.
  ///
  /// In en, this message translates to:
  /// **'Clarified'**
  String get statusClarified;

  /// No description provided for @clarify.
  ///
  /// In en, this message translates to:
  /// **'Clarify'**
  String get clarify;

  /// No description provided for @clearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearDate;

  /// No description provided for @emptyTasks.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get emptyTasks;

  /// No description provided for @taskTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitle;

  /// No description provided for @taskNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get taskNotes;

  /// No description provided for @taskDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get taskDueDate;

  /// No description provided for @taskScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get taskScheduled;

  /// No description provided for @taskEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get taskEnergy;

  /// No description provided for @taskPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskPriority;

  /// No description provided for @taskStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get taskStatus;

  /// No description provided for @taskWaitingOn.
  ///
  /// In en, this message translates to:
  /// **'Waiting on'**
  String get taskWaitingOn;

  /// No description provided for @taskProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get taskProject;

  /// No description provided for @taskContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get taskContext;

  /// No description provided for @taskTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get taskTags;

  /// No description provided for @noProject.
  ///
  /// In en, this message translates to:
  /// **'No project'**
  String get noProject;

  /// No description provided for @noContext.
  ///
  /// In en, this message translates to:
  /// **'No context'**
  String get noContext;

  /// No description provided for @statusNextAction.
  ///
  /// In en, this message translates to:
  /// **'Next action'**
  String get statusNextAction;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusWaiting;

  /// No description provided for @statusSomeday.
  ///
  /// In en, this message translates to:
  /// **'Someday'**
  String get statusSomeday;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @clarifyOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original note'**
  String get clarifyOriginal;

  /// No description provided for @clarifyDetails.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get clarifyDetails;

  /// No description provided for @clarifyCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create action'**
  String get clarifyCreateAction;

  /// No description provided for @clarifyCreateProject.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get clarifyCreateProject;

  /// No description provided for @decisionAction.
  ///
  /// In en, this message translates to:
  /// **'Turn into action'**
  String get decisionAction;

  /// No description provided for @decisionProject.
  ///
  /// In en, this message translates to:
  /// **'Turn into project'**
  String get decisionProject;

  /// No description provided for @decisionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get decisionDelete;

  /// No description provided for @projectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectName;

  /// No description provided for @projectGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get projectGoal;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get newProject;

  /// No description provided for @editProject.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get editProject;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get markDone;

  /// No description provided for @reopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopen;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get repeatDaily;

  /// No description provided for @repeatEveryN.
  ///
  /// In en, this message translates to:
  /// **'Every N days'**
  String get repeatEveryN;

  /// No description provided for @repeatIntervalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an integer from 1 to 365'**
  String get repeatIntervalInvalid;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @repeatNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get repeatNone;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @reviewSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reviewSummary;

  /// No description provided for @reviewDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks done'**
  String get reviewDone;

  /// No description provided for @reviewNew.
  ///
  /// In en, this message translates to:
  /// **'New tasks'**
  String get reviewNew;

  /// No description provided for @reviewStalled.
  ///
  /// In en, this message translates to:
  /// **'Stalled'**
  String get reviewStalled;

  /// No description provided for @saveReview.
  ///
  /// In en, this message translates to:
  /// **'Save review'**
  String get saveReview;

  /// No description provided for @newReview.
  ///
  /// In en, this message translates to:
  /// **'New review'**
  String get newReview;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get langSystem;

  /// No description provided for @langZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export backup (JSON)'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup (JSON)'**
  String get importBackup;

  /// No description provided for @exportedTo.
  ///
  /// In en, this message translates to:
  /// **'Backup exported'**
  String get exportedTo;

  /// No description provided for @importedFrom.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get importedFrom;

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get backupInvalid;

  /// No description provided for @aiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'AI model config (available in M2)'**
  String get aiPlaceholder;

  /// No description provided for @waitingOnRequired.
  ///
  /// In en, this message translates to:
  /// **'Waiting on is required for waiting tasks.'**
  String get waitingOnRequired;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @todayTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 task} other{{count} tasks}}'**
  String todayTaskCount(int count);

  /// No description provided for @todayOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String todayOverdue(int count);

  /// No description provided for @upcomingTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get upcomingTomorrow;

  /// No description provided for @upcomingDayAfter.
  ///
  /// In en, this message translates to:
  /// **'Day after tomorrow'**
  String get upcomingDayAfter;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @upcomingDateHeader.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day} {weekday}'**
  String upcomingDateHeader(int month, int day, String weekday);

  /// No description provided for @logbookSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No matching tasks.'**
  String get logbookSearchEmpty;

  /// No description provided for @logbookSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get logbookSearchHint;

  /// No description provided for @logbookDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get logbookDeleteConfirm;

  /// No description provided for @logbookRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get logbookRestore;

  /// No description provided for @taskListSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String taskListSelectedCount(int count);

  /// No description provided for @exitSelection.
  ///
  /// In en, this message translates to:
  /// **'Exit selection'**
  String get exitSelection;

  /// No description provided for @actionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get actionComplete;

  /// No description provided for @actionSetDate.
  ///
  /// In en, this message translates to:
  /// **'Set date'**
  String get actionSetDate;

  /// No description provided for @actionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get actionMove;

  /// No description provided for @reminderBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminder: {title}'**
  String reminderBannerTitle(String title);

  /// No description provided for @reminderOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get reminderOpen;

  /// No description provided for @reminderDismiss.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get reminderDismiss;

  /// No description provided for @navGuide.
  ///
  /// In en, this message translates to:
  /// **'GTD Guide'**
  String get navGuide;

  /// No description provided for @settingsGuide.
  ///
  /// In en, this message translates to:
  /// **'View GTD Guide'**
  String get settingsGuide;

  /// No description provided for @ruleInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Collect, don\'t organize'**
  String get ruleInboxTitle;

  /// No description provided for @ruleInboxMessage.
  ///
  /// In en, this message translates to:
  /// **'Start each item with a verb and state the next action.'**
  String get ruleInboxMessage;

  /// No description provided for @ruleTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today is 1-3-5'**
  String get ruleTodayTitle;

  /// No description provided for @ruleTodayMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep 1 big, 3 medium, and 5 small tasks. Add more only after finishing.'**
  String get ruleTodayMessage;

  /// No description provided for @ruleUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Hard time only'**
  String get ruleUpcomingTitle;

  /// No description provided for @ruleUpcomingMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep meetings and deadlines here. Drag a task onto a date header to schedule it.'**
  String get ruleUpcomingMessage;

  /// No description provided for @ruleAnytimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Do anytime'**
  String get ruleAnytimeTitle;

  /// No description provided for @ruleAnytimeMessage.
  ///
  /// In en, this message translates to:
  /// **'Tasks you\'ll do soon, without a fixed day, live here.'**
  String get ruleAnytimeMessage;

  /// No description provided for @ruleSomedayTitle.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get ruleSomedayTitle;

  /// No description provided for @ruleSomedayMessage.
  ///
  /// In en, this message translates to:
  /// **'Not now, maybe later — take a look during the weekly review.'**
  String get ruleSomedayMessage;

  /// No description provided for @ruleProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Every project needs a next action'**
  String get ruleProjectsTitle;

  /// No description provided for @ruleProjectsMessage.
  ///
  /// In en, this message translates to:
  /// **'Give each project a concrete next action and a specific goal.'**
  String get ruleProjectsMessage;

  /// No description provided for @ruleContextsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter by context'**
  String get ruleContextsTitle;

  /// No description provided for @ruleContextsMessage.
  ///
  /// In en, this message translates to:
  /// **'Filter by place or mood — @work, @home — and do what fits where you are.'**
  String get ruleContextsMessage;

  /// No description provided for @ruleWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a follow-up date'**
  String get ruleWaitingTitle;

  /// No description provided for @ruleWaitingMessage.
  ///
  /// In en, this message translates to:
  /// **'Every waiting item needs a follow-up date; scan today\'s due follow-ups every day.'**
  String get ruleWaitingMessage;

  /// No description provided for @ruleLogbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Done stays here'**
  String get ruleLogbookTitle;

  /// No description provided for @ruleLogbookMessage.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks are kept automatically — count them at your weekly review.'**
  String get ruleLogbookMessage;

  /// No description provided for @ruleReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'20 minutes, every week'**
  String get ruleReviewTitle;

  /// No description provided for @ruleReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Empty the inbox, follow up on waiting, advance projects, activate somedays, and check for hard-time conflicts.'**
  String get ruleReviewMessage;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Settle'**
  String get onboardingTitle;

  /// No description provided for @ironRule1.
  ///
  /// In en, this message translates to:
  /// **'Capture everything into the inbox'**
  String get ironRule1;

  /// No description provided for @ironRule2.
  ///
  /// In en, this message translates to:
  /// **'Do it now if it takes two minutes'**
  String get ironRule2;

  /// No description provided for @ironRule3.
  ///
  /// In en, this message translates to:
  /// **'Keep today to 1-3-5'**
  String get ironRule3;

  /// No description provided for @dailyAction1.
  ///
  /// In en, this message translates to:
  /// **'Morning: review Today'**
  String get dailyAction1;

  /// No description provided for @dailyAction2.
  ///
  /// In en, this message translates to:
  /// **'Evening: clear the inbox, check things off, set tomorrow\'s top task'**
  String get dailyAction2;

  /// No description provided for @dailyAction3.
  ///
  /// In en, this message translates to:
  /// **'Sunday: 20-minute review'**
  String get dailyAction3;

  /// No description provided for @onboardingOpenGuide.
  ///
  /// In en, this message translates to:
  /// **'View the full guide →'**
  String get onboardingOpenGuide;

  /// No description provided for @onboardingClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get onboardingClose;

  /// No description provided for @guideSectionLaws.
  ///
  /// In en, this message translates to:
  /// **'Three iron rules'**
  String get guideSectionLaws;

  /// No description provided for @guideSectionDaily.
  ///
  /// In en, this message translates to:
  /// **'A daily rhythm'**
  String get guideSectionDaily;

  /// No description provided for @guideSectionLists.
  ///
  /// In en, this message translates to:
  /// **'How to use each list'**
  String get guideSectionLists;

  /// No description provided for @guideSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get guideSectionNotes;

  /// No description provided for @guideExampleInbox.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Email the client to confirm the quote\"'**
  String get guideExampleInbox;

  /// No description provided for @guideExampleToday.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1 big \"write the weekly report\" + 3 medium + 5 small'**
  String get guideExampleToday;

  /// No description provided for @guideExampleWaiting.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"Waiting on the vendor quote — follow up Friday\"'**
  String get guideExampleWaiting;

  /// No description provided for @guideExampleProject.
  ///
  /// In en, this message translates to:
  /// **'e.g. project \"Moving\" → next action \"call movers for a quote\"'**
  String get guideExampleProject;

  /// No description provided for @guideExampleSomeday.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"learn guitar\", \"visit Iceland\"'**
  String get guideExampleSomeday;

  /// No description provided for @guideExampleUpcoming.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wednesday 14:00 meeting, Friday submission deadline'**
  String get guideExampleUpcoming;

  /// No description provided for @guideNote1.
  ///
  /// In en, this message translates to:
  /// **'Reminders are in-app only — rely on your own attention for what matters.'**
  String get guideNote1;

  /// No description provided for @guideNote2.
  ///
  /// In en, this message translates to:
  /// **'Keep important deadlines in your calendar too — belt and braces.'**
  String get guideNote2;

  /// No description provided for @guideNote3.
  ///
  /// In en, this message translates to:
  /// **'Never skip the weekly review — it\'s what keeps the system under control.'**
  String get guideNote3;

  /// No description provided for @guideNote4.
  ///
  /// In en, this message translates to:
  /// **'Export a JSON backup anytime.'**
  String get guideNote4;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
