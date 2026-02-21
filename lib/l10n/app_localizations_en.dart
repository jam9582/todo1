// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionCalendar => 'Calendar Settings';

  @override
  String get labelWeekStart => 'Week Start Day';

  @override
  String get sunday => 'Sunday';

  @override
  String get monday => 'Monday';

  @override
  String get sectionCalendarDisplay => 'Calendar Display';

  @override
  String get labelCategoryDisplay => 'Category Display Mode';

  @override
  String get displayModeTopCategory => 'Most Active';

  @override
  String get displayModeFixedCategory => 'Fixed Category';

  @override
  String get labelDisplayCategory => 'Category to Display';

  @override
  String get dropdownHint => 'Select';

  @override
  String get labelShowActivityTime => 'Show Activity Time';

  @override
  String get labelShowCheckCount => 'Show Checkbox Count';

  @override
  String get sectionNotification => 'Notifications';

  @override
  String get labelDailyNotif => 'Daily Notification';

  @override
  String get labelNotifTime => 'Notification Time';

  @override
  String get sectionPurchase => 'Purchase';

  @override
  String get labelRestorePurchase => 'Restore Purchase';

  @override
  String get labelPurchaseHistory => 'Purchase History & Support';

  @override
  String get sectionAppInfo => 'App Info';

  @override
  String get labelVersion => 'Version';

  @override
  String get msgPurchaseRestored => 'Purchases restored!';

  @override
  String get msgNoPurchaseToRestore => 'No purchases to restore';

  @override
  String get msgRestoreFailed => 'Restore failed. Please try again.';

  @override
  String get menuStatistics => 'Statistics';

  @override
  String get menuCategoryEdit => 'Edit Categories';

  @override
  String get menuRemoveAds => 'Remove Ads';

  @override
  String get msgAdsAlreadyRemoved => 'Ads already removed ✓';

  @override
  String get msgAdsRemoved => 'Ads removed!';

  @override
  String get periodWeekly => 'Weekly';

  @override
  String get periodMonthly => 'Monthly';

  @override
  String get noData => 'No data';

  @override
  String get chartWeeklyTrend => 'Weekly Activity';

  @override
  String get chartMonthlyTrend => 'Monthly Activity';

  @override
  String get chartWeeklyTotal => 'Weekly Category Total';

  @override
  String get chartMonthlyTotal => 'Monthly Category Total';

  @override
  String get dailyMessageLabel => 'Today\'s Note';

  @override
  String get dailyMessagePlaceholder => 'Always cheering for you';

  @override
  String get emptyCategoryMessage => 'Create your first category!';

  @override
  String get tabCategory => 'Category';

  @override
  String get tabCheckbox => 'Checkbox';

  @override
  String get dialogDeleteCategoryTitle => 'Delete Category';

  @override
  String dialogDeleteCategoryContent(String name) {
    return 'Delete the \'$name\' category?';
  }

  @override
  String get dialogDeleteCheckboxTitle => 'Delete Checkbox';

  @override
  String dialogDeleteCheckboxContent(String name) {
    return 'Delete the \'$name\' item?';
  }

  @override
  String get emptyCheckboxMessage => 'Add your first checkbox';

  @override
  String addItemMax(int count) {
    return 'Max $count';
  }

  @override
  String get checkboxAdd => 'Add Checkbox';

  @override
  String get categoryAdd => 'Add Category';

  @override
  String get dialogEditCategoryTitle => 'Edit Category';

  @override
  String get dialogNewCategoryTitle => 'New Category';

  @override
  String get hintCategoryName => 'Category name';

  @override
  String get dialogEditCheckboxTitle => 'Edit Checkbox';

  @override
  String get dialogNewCheckboxTitle => 'New Checkbox';

  @override
  String get hintTaskName => 'Task name';

  @override
  String get notifChannelName => 'Daily Reminder';

  @override
  String get notifTitle => 'How was your day?';

  @override
  String get notifBody => 'Record your activities for today.';
}
