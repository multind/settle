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
  /// **'GTD'**
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

  /// No description provided for @emptyInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox is empty. Capture your first thought above.'**
  String get emptyInbox;

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

  /// No description provided for @todayOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String todayOverdue(int count);

  /// No description provided for @todayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled today.'**
  String get todayEmpty;

  /// No description provided for @anytimeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks anytime.'**
  String get anytimeEmpty;

  /// No description provided for @upcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming tasks.'**
  String get upcomingEmpty;

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

  /// No description provided for @logbookEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.'**
  String get logbookEmpty;

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
