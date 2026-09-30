// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Vehicles';

  @override
  String get vehicles => 'Vehicles';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get addVehicle => 'Add vehicle';

  @override
  String get editVehicle => 'Edit vehicle';

  @override
  String get deleteVehicle => 'Delete vehicle';

  @override
  String get addMaintenance => 'Log maintenance';

  @override
  String get editMaintenance => 'Edit maintenance';

  @override
  String get deleteMaintenance => 'Delete record';

  @override
  String get vehicleName => 'Vehicle name';

  @override
  String get vehicleType => 'Vehicle type';

  @override
  String get car => 'Car / Pickup';

  @override
  String get motorcycle => 'Motorcycle';

  @override
  String get brand => 'Brand';

  @override
  String get model => 'Model';

  @override
  String get year => 'Year';

  @override
  String get licensePlate => 'License plate';

  @override
  String get currentKm => 'Current mileage (km)';

  @override
  String get maintenanceType => 'Maintenance type';

  @override
  String get date => 'Date';

  @override
  String get kmAtService => 'Km at service';

  @override
  String get cost => 'Cost';

  @override
  String get mechanic => 'Shop / Mechanic';

  @override
  String get productsUsed => 'Products used';

  @override
  String get notes => 'Notes';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get refresh => 'Refresh';

  @override
  String get understood => 'Got it';

  @override
  String get show => 'Show';

  @override
  String get hide => 'Hide';

  @override
  String get nameLabel => 'Name';

  @override
  String get iconLabel => 'Icon';

  @override
  String get emojiHint => 'Tap one or type any emoji.';

  @override
  String get confirmDeleteVehicle => 'Delete this vehicle and all its history?';

  @override
  String get confirmDeleteMaintenance => 'Delete this maintenance record?';

  @override
  String get noVehicles => 'No vehicles yet.\nTap + to add one.';

  @override
  String get noHistory => 'No maintenance records.';

  @override
  String get noRecommendations =>
      'No pending recommendations.\nAll up to date!';

  @override
  String get exportCSV => 'Export CSV';

  @override
  String get exportPDF => 'Export PDF';

  @override
  String get exportError => 'Export failed';

  @override
  String get language => 'Language';

  @override
  String get spanish => 'Spanish';

  @override
  String get english => 'English';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get invalidYear => 'Invalid year';

  @override
  String get updateKm => 'Update mileage';

  @override
  String get maintenanceHistory => 'Maintenance history';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get high => 'High';

  @override
  String get medium => 'Medium';

  @override
  String get low => 'Low';

  @override
  String get unitKm => 'km';

  @override
  String get unitDays => 'days';

  @override
  String get hintVehicleName => 'My car, Work bike...';

  @override
  String get hintBrand => 'Toyota, Honda, Yamaha...';

  @override
  String get hintModel => 'Corolla, CBR500, MT-03...';

  @override
  String get hintPlate => 'ABC 123';

  @override
  String get chooseVehicleType => 'Choose a vehicle type.';

  @override
  String get noVehicleTypes =>
      'There are no vehicle types. Create one in Settings → Vehicle types.';

  @override
  String get kmReminderTitle => 'Mileage reminder';

  @override
  String get kmReminderSubtitle =>
      'A weekly notification asks for the current km to estimate when each service is due.';

  @override
  String get dayLabel => 'Day';

  @override
  String get timeLabel => 'Time';

  @override
  String get notificationPermissionDenied =>
      'Without notification permission, reminders won\'t show up. Enable it in the system settings.';

  @override
  String get weekday1 => 'Monday';

  @override
  String get weekday2 => 'Tuesday';

  @override
  String get weekday3 => 'Wednesday';

  @override
  String get weekday4 => 'Thursday';

  @override
  String get weekday5 => 'Friday';

  @override
  String get weekday6 => 'Saturday';

  @override
  String get weekday7 => 'Sunday';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return '$_temp0';
  }

  @override
  String kmPerWeek(String km) {
    return '~$km km/wk';
  }

  @override
  String get usageHintTitle => 'Usage-based estimate';

  @override
  String get usageHintWithReminder =>
      'Once there is at least a week of km readings, each service date will be estimated from how much you use the vehicle.';

  @override
  String get usageHintWithoutReminder =>
      'Turn on the mileage reminder (Edit vehicle) or update the km now and then, and each service date will be estimated from how much you use the vehicle.';

  @override
  String hiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maintenance items hidden for this vehicle',
      one: '1 maintenance hidden for this vehicle',
    );
    return '$_temp0';
  }

  @override
  String get hiddenTitle => 'Hidden maintenance';

  @override
  String get kmInvalid => 'Not saved: type only the km number.';

  @override
  String kmLowerThanCurrent(String km, String current) {
    return 'Not saved: $km km is less than the $current km already recorded.';
  }

  @override
  String overrideHelp(String vehicle) {
    return 'Interval only for $vehicle. Leave it empty to use the type\'s.';
  }

  @override
  String get everyKmLabel => 'Every how many km';

  @override
  String get everyDaysLabel => 'Every how many days';

  @override
  String fromType(String value) {
    return 'From type: $value';
  }

  @override
  String get fromTypeNoKm => 'From type: not tracked by km';

  @override
  String get fromTypeNoDays => 'From type: not tracked by time';

  @override
  String get zeroDisables => 'Enter 0 to stop tracking by that criterion.';

  @override
  String get statusOverdue => 'OVERDUE';

  @override
  String get statusDueSoon => 'DUE SOON';

  @override
  String get statusPending => 'NO RECORD';

  @override
  String get statusOk => 'UP TO DATE';

  @override
  String get pendingRecordText =>
      'No record. Counting from 0 km it was already due: log the last service you did so the next one can be calculated.';

  @override
  String lastService(String date, String km) {
    return 'Last: $date · $km km';
  }

  @override
  String get firstServiceNoRecord => 'First service (no record yet)';

  @override
  String kmOverdue(String km) {
    return '$km km overdue';
  }

  @override
  String kmRemainingNext(String km, String next) {
    return '$km km left (next: $next km)';
  }

  @override
  String daysOverdue(String days) {
    return '$days days overdue';
  }

  @override
  String daysRemainingDate(String days, String date) {
    return '$days days left ($date)';
  }

  @override
  String usageAlreadyNear(String km) {
    return 'Based on your usage you should be near $km km by now: update the km';
  }

  @override
  String usageTomorrow(String km) {
    return 'Based on your usage you\'d reach $km km tomorrow';
  }

  @override
  String usageInDays(String km, String days, String date) {
    return 'Based on your usage you\'d reach $km km in ~$days days (~$date)';
  }

  @override
  String get ownInterval => 'Custom interval for this vehicle';

  @override
  String get actionRegister => 'Log service';

  @override
  String get actionCustomize => 'Customize interval';

  @override
  String get actionSchedule => 'Schedule appointment';

  @override
  String get actionEditAppointment => 'Edit appointment';

  @override
  String appointmentLine(String date) {
    return '📅 Appointment: $date';
  }

  @override
  String appointmentLineShop(String date, String shop) {
    return '📅 Appointment: $date at $shop';
  }

  @override
  String get appointmentPast =>
      'The appointment has passed: log the service or delete it.';

  @override
  String get appointmentTitle => 'Appointment';

  @override
  String get appointmentHelp =>
      'You\'ll get a reminder on the date you choose. Whatever is in the appointment doesn\'t use the automatic time or km reminder.';

  @override
  String get appointmentsSection => 'Appointments';

  @override
  String get newAppointment => 'New appointment';

  @override
  String get appointmentWhatToDo => 'What will be done?';

  @override
  String get appointmentSuggested =>
      'Overdue, due soon and never-logged items come pre-selected.';

  @override
  String get appointmentSelectAtLeastOne =>
      'Pick at least one maintenance item.';

  @override
  String get deleteAppointmentQuestion => 'Delete this appointment?';

  @override
  String get completeAppointment => 'Log what was done';

  @override
  String get completeAppointmentTitle => 'Log appointment services';

  @override
  String get completeAppointmentHelp =>
      'A record is created for each checked item and the appointment is closed. Uncheck whatever wasn\'t done in the end.';

  @override
  String get costOptional => 'Cost (optional)';

  @override
  String get remindMe => 'Remind me';

  @override
  String get remindAtTime => 'At the appointment time';

  @override
  String get remindHourBefore => '1 hour before';

  @override
  String get remindDayBefore => '1 day before';

  @override
  String get appointmentDelete => 'Delete appointment';

  @override
  String get appointmentInPast => 'Pick a future date and time.';

  @override
  String appointmentNotifTitle(String vehicle) {
    return '📅 Appointment · $vehicle';
  }

  @override
  String appointmentNotifBody(String when, String items) {
    return '$when: $items';
  }

  @override
  String appointmentNotifBodyShop(String when, String shop, String items) {
    return '$when at $shop: $items';
  }

  @override
  String get noActiveMaintenance =>
      'This vehicle type has no active maintenance. Add some in Settings → Vehicle types.';

  @override
  String get mechanicHint => 'Shop or mechanic name';

  @override
  String get pickFromList => 'Pick from the list';

  @override
  String get productsHint => 'Shell 10W-40, Fram filter...';

  @override
  String get notesHint => 'Additional notes...';

  @override
  String get catalogsSection => 'Catalogs';

  @override
  String get vehicleTypesAndMaintenance => 'Vehicle types and maintenance';

  @override
  String get vehicleTypesSubtitle =>
      'What is tracked for each type and how often';

  @override
  String get mechanicsTitle => 'Shops and mechanics';

  @override
  String get maintenanceRemindersSection => 'Maintenance reminders';

  @override
  String get remindBeforeService => 'Remind me before each service';

  @override
  String get remindBeforeServiceSub =>
      'By date or by estimated usage, whichever comes first';

  @override
  String get advance => 'Advance notice';

  @override
  String get sameDay => 'Same day';

  @override
  String daysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get howManyDaysBefore => 'How many days before?';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get dueSoonSection => 'When a service becomes DUE SOON';

  @override
  String get lessThan => 'Less than';

  @override
  String get orLessThan => 'or less than';

  @override
  String get kmAdvance => 'Km in advance';

  @override
  String get daysAdvance => 'Days in advance';

  @override
  String get dataSection => 'Data';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get exportBackupSub =>
      'One file with everything, to keep or move to another phone';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get restoreBackupSub => 'Replaces the current data';

  @override
  String get backupError => 'Couldn\'t create the backup.';

  @override
  String get restoreConfirmTitle => 'Restore this backup?';

  @override
  String restoreConfirmVehicles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It contains $count vehicles.',
      one: 'It contains 1 vehicle.',
    );
    return '$_temp0';
  }

  @override
  String get restoreConfirmWarning =>
      'ALL current app data will be REPLACED: anything not in the backup will be lost.';

  @override
  String get replaceAll => 'Replace everything';

  @override
  String get restoreDone => 'Backup restored.';

  @override
  String get restoreFailed =>
      'Couldn\'t restore the backup. Your previous data was not changed.';

  @override
  String get backupInvalidFile => 'The file is not a valid backup.';

  @override
  String get backupNotOurs => 'The file is not a My Vehicles backup.';

  @override
  String get backupTooNew =>
      'The backup is from a newer version of the app. Update it first.';

  @override
  String get backupShareSubject => 'My Vehicles backup';

  @override
  String get updateNotifTitle => 'A new version of My Vehicles is out';

  @override
  String updateNotifBody(String version) {
    return 'Version $version is ready. Tap to download it.';
  }

  @override
  String get updateChannelName => 'Updates';

  @override
  String get updateChannelDescription =>
      'Notice when a new version of the app is available';

  @override
  String updateDialogTitle(String version) {
    return 'Version $version available';
  }

  @override
  String updateDialogBody(String current) {
    return 'You have $current. Download the APK and install it over this one: no data is lost.';
  }

  @override
  String get updateDownload => 'Download';

  @override
  String get updateLater => 'Later';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get checkingUpdates => 'Checking…';

  @override
  String get upToDate => 'You have the latest version';

  @override
  String updateAvailableShort(String version) {
    return 'Version $version available, tap to download';
  }

  @override
  String get updateCheckFailed =>
      'Couldn\'t check. Verify your internet connection.';

  @override
  String get updateOpenError => 'Couldn\'t open the download link';

  @override
  String get aboutSection => 'About';

  @override
  String get developedBy => 'Developed by';

  @override
  String get instagramOpenError => 'Couldn\'t open Instagram.';

  @override
  String get storage => 'Storage';

  @override
  String get storageText =>
      'All data is stored only on your phone. The app only goes online to check for a new version.';

  @override
  String get vehicleTypesTitle => 'Vehicle types';

  @override
  String get vehicleTypesHelp =>
      'Each type has its own maintenance list. Tap one to configure it.';

  @override
  String activeMaintenanceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active maintenance items',
      one: '1 active maintenance',
      zero: 'No active maintenance',
    );
    return '$_temp0';
  }

  @override
  String get newType => 'New type';

  @override
  String get editType => 'Edit type';

  @override
  String get typeNameHint => 'Truck, ATV, Boat...';

  @override
  String get cannotDelete => 'Can\'t delete';

  @override
  String typeInUse(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'There are $count vehicles of type \"$name\". Change their type or delete them first.',
      one:
          'There is 1 vehicle of type \"$name\". Change its type or delete it first.',
    );
    return '$_temp0';
  }

  @override
  String deleteQuestion(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteTypeAlsoMaintenance =>
      'Its maintenance items are deleted too.';

  @override
  String get copyFromOtherType => 'Copy from another type';

  @override
  String get copyMaintenanceFrom => 'Copy maintenance from…';

  @override
  String get noMaintenanceForType =>
      'There is no maintenance for this type yet.';

  @override
  String get newItem => 'New';

  @override
  String get newMaintenance => 'New maintenance';

  @override
  String get noInterval => 'No interval (log only)';

  @override
  String everyKm(String km) {
    return 'every $km km';
  }

  @override
  String everyDays(String days) {
    return 'every $days days';
  }

  @override
  String get orSeparator => ' or ';

  @override
  String whicheverFirst(String parts) {
    return '$parts · whichever comes first';
  }

  @override
  String get hasHistoryTitle => 'It has history';

  @override
  String hasHistoryBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\"$name\" has $count records.',
      one: '\"$name\" has 1 record.',
    );
    return '$_temp0 If you delete it, that history loses its name. Deactivate it instead? It stops showing in recommendations and when logging, but the history is kept.';
  }

  @override
  String get deleteAnyway => 'Delete anyway';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get intervalLabel => 'Interval';

  @override
  String get intervalHelp =>
      'Due by km or by time, whichever comes first. Leave empty whatever isn\'t tracked; with both empty it\'s only for logging.';

  @override
  String get everyLabel => 'Every';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get unknownMaintenance => 'Deleted maintenance';

  @override
  String get mechanicsEmpty =>
      'No shops yet. Add the ones you use, or they get added automatically when you type a new one while logging a service.';

  @override
  String get deleteMechanicBody =>
      'It\'s only removed from the list: logged services keep the shop name.';

  @override
  String get callError => 'Couldn\'t open the phone app.';

  @override
  String get newMechanic => 'New shop';

  @override
  String get editMechanic => 'Edit shop';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get notesLabel => 'Notes';

  @override
  String kmPromptTitle(String vehicle) {
    return 'How many km does $vehicle have?';
  }

  @override
  String get kmPromptBody =>
      'Enter the current mileage to estimate the next maintenance.';

  @override
  String get kmActionLabel => 'Enter km';

  @override
  String get kmInputLabel => 'Current km (numbers only)';

  @override
  String kmSaved(String km) {
    return 'Saved: $km km.';
  }

  @override
  String kmNotValid(String text) {
    return 'Not saved: \"$text\" is not a valid km. Type only the number, e.g. 45000.';
  }

  @override
  String get kmVehicleGone => 'Not saved: the vehicle no longer exists.';

  @override
  String get genericVehicle => 'Vehicle';

  @override
  String get channelKm => 'Mileage';

  @override
  String get channelKmDesc => 'Weekly reminder to enter the km';

  @override
  String get channelMaintenance => 'Vehicle maintenance';

  @override
  String get channelMaintenanceDesc => 'Reminders before a maintenance is due';

  @override
  String maintenanceDueDate(String date) {
    return 'It\'s due on $date.';
  }

  @override
  String maintenanceDueUsage(String km, String date) {
    return 'Based on your usage you\'d reach $km km around $date.';
  }

  @override
  String get pdfTitle => 'Maintenance history';

  @override
  String get pdfVehicle => 'Vehicle';

  @override
  String get totalCostLabel => 'Total cost';

  @override
  String recordsTitle(String count) {
    return 'Records ($count)';
  }

  @override
  String get noRecords => 'No records';

  @override
  String generatedOn(String date) {
    return 'Generated on $date with My Vehicles';
  }

  @override
  String get fileSuffixMaintenance => 'maintenance';
}
