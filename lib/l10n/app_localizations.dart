import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis Vehículos'**
  String get appTitle;

  /// No description provided for @vehicles.
  ///
  /// In es, this message translates to:
  /// **'Vehículos'**
  String get vehicles;

  /// No description provided for @maintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get maintenance;

  /// No description provided for @history.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @addVehicle.
  ///
  /// In es, this message translates to:
  /// **'Agregar vehículo'**
  String get addVehicle;

  /// No description provided for @editVehicle.
  ///
  /// In es, this message translates to:
  /// **'Editar vehículo'**
  String get editVehicle;

  /// No description provided for @deleteVehicle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar vehículo'**
  String get deleteVehicle;

  /// No description provided for @addMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Registrar mantenimiento'**
  String get addMaintenance;

  /// No description provided for @editMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Editar mantenimiento'**
  String get editMaintenance;

  /// No description provided for @deleteMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Eliminar registro'**
  String get deleteMaintenance;

  /// No description provided for @vehicleName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del vehículo'**
  String get vehicleName;

  /// No description provided for @vehicleType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de vehículo'**
  String get vehicleType;

  /// No description provided for @car.
  ///
  /// In es, this message translates to:
  /// **'Auto / Camioneta'**
  String get car;

  /// No description provided for @motorcycle.
  ///
  /// In es, this message translates to:
  /// **'Moto'**
  String get motorcycle;

  /// No description provided for @brand.
  ///
  /// In es, this message translates to:
  /// **'Marca'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In es, this message translates to:
  /// **'Modelo'**
  String get model;

  /// No description provided for @year.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get year;

  /// No description provided for @licensePlate.
  ///
  /// In es, this message translates to:
  /// **'Patente'**
  String get licensePlate;

  /// No description provided for @currentKm.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje actual'**
  String get currentKm;

  /// No description provided for @maintenanceType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de mantenimiento'**
  String get maintenanceType;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @kmAtService.
  ///
  /// In es, this message translates to:
  /// **'Km al momento del servicio'**
  String get kmAtService;

  /// No description provided for @cost.
  ///
  /// In es, this message translates to:
  /// **'Costo'**
  String get cost;

  /// No description provided for @mechanic.
  ///
  /// In es, this message translates to:
  /// **'Taller / Mecánico'**
  String get mechanic;

  /// No description provided for @productsUsed.
  ///
  /// In es, this message translates to:
  /// **'Productos utilizados'**
  String get productsUsed;

  /// No description provided for @notes.
  ///
  /// In es, this message translates to:
  /// **'Notas / Observaciones'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @refresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get refresh;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @show.
  ///
  /// In es, this message translates to:
  /// **'Mostrar'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In es, this message translates to:
  /// **'Ocultar'**
  String get hide;

  /// No description provided for @nameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get nameLabel;

  /// No description provided for @iconLabel.
  ///
  /// In es, this message translates to:
  /// **'Ícono'**
  String get iconLabel;

  /// No description provided for @emojiHint.
  ///
  /// In es, this message translates to:
  /// **'Tocá uno o escribí cualquier emoji.'**
  String get emojiHint;

  /// No description provided for @confirmDeleteVehicle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este vehículo y todo su historial?'**
  String get confirmDeleteVehicle;

  /// No description provided for @confirmDeleteMaintenance.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este registro de mantenimiento?'**
  String get confirmDeleteMaintenance;

  /// No description provided for @noVehicles.
  ///
  /// In es, this message translates to:
  /// **'No hay vehículos registrados.\nTocá + para agregar uno.'**
  String get noVehicles;

  /// No description provided for @noHistory.
  ///
  /// In es, this message translates to:
  /// **'No hay registros de mantenimiento.'**
  String get noHistory;

  /// No description provided for @noRecommendations.
  ///
  /// In es, this message translates to:
  /// **'No hay recomendaciones pendientes.\n¡Todo al día!'**
  String get noRecommendations;

  /// No description provided for @exportCSV.
  ///
  /// In es, this message translates to:
  /// **'Exportar CSV'**
  String get exportCSV;

  /// No description provided for @exportPDF.
  ///
  /// In es, this message translates to:
  /// **'Exportar PDF'**
  String get exportPDF;

  /// No description provided for @exportError.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar'**
  String get exportError;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @spanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @english.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get english;

  /// No description provided for @fieldRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get fieldRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In es, this message translates to:
  /// **'Ingresá un número válido'**
  String get invalidNumber;

  /// No description provided for @invalidYear.
  ///
  /// In es, this message translates to:
  /// **'Año inválido'**
  String get invalidYear;

  /// No description provided for @updateKm.
  ///
  /// In es, this message translates to:
  /// **'Actualizar kilometraje'**
  String get updateKm;

  /// No description provided for @maintenanceHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de mantenimiento'**
  String get maintenanceHistory;

  /// No description provided for @recommendations.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get recommendations;

  /// No description provided for @high.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get high;

  /// No description provided for @medium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get medium;

  /// No description provided for @low.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get low;

  /// No description provided for @unitKm.
  ///
  /// In es, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @unitDays.
  ///
  /// In es, this message translates to:
  /// **'días'**
  String get unitDays;

  /// No description provided for @hintVehicleName.
  ///
  /// In es, this message translates to:
  /// **'Mi auto, Moto del trabajo...'**
  String get hintVehicleName;

  /// No description provided for @hintBrand.
  ///
  /// In es, this message translates to:
  /// **'Toyota, Honda, Yamaha...'**
  String get hintBrand;

  /// No description provided for @hintModel.
  ///
  /// In es, this message translates to:
  /// **'Corolla, CBR500, MT-03...'**
  String get hintModel;

  /// No description provided for @hintPlate.
  ///
  /// In es, this message translates to:
  /// **'ABC 123'**
  String get hintPlate;

  /// No description provided for @chooseVehicleType.
  ///
  /// In es, this message translates to:
  /// **'Elegí un tipo de vehículo.'**
  String get chooseVehicleType;

  /// No description provided for @noVehicleTypes.
  ///
  /// In es, this message translates to:
  /// **'No hay tipos de vehículo. Creá uno en Configuración → Tipos de vehículo.'**
  String get noVehicleTypes;

  /// No description provided for @kmReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio de kilometraje'**
  String get kmReminderTitle;

  /// No description provided for @kmReminderSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Una notificación semanal te pregunta el km actual para estimar cuándo toca cada mantenimiento.'**
  String get kmReminderSubtitle;

  /// No description provided for @dayLabel.
  ///
  /// In es, this message translates to:
  /// **'Día'**
  String get dayLabel;

  /// No description provided for @timeLabel.
  ///
  /// In es, this message translates to:
  /// **'Hora'**
  String get timeLabel;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso de notificaciones los avisos no van a aparecer. Habilitalo en Ajustes del sistema.'**
  String get notificationPermissionDenied;

  /// No description provided for @weekday1.
  ///
  /// In es, this message translates to:
  /// **'Lunes'**
  String get weekday1;

  /// No description provided for @weekday2.
  ///
  /// In es, this message translates to:
  /// **'Martes'**
  String get weekday2;

  /// No description provided for @weekday3.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get weekday3;

  /// No description provided for @weekday4.
  ///
  /// In es, this message translates to:
  /// **'Jueves'**
  String get weekday4;

  /// No description provided for @weekday5.
  ///
  /// In es, this message translates to:
  /// **'Viernes'**
  String get weekday5;

  /// No description provided for @weekday6.
  ///
  /// In es, this message translates to:
  /// **'Sábado'**
  String get weekday6;

  /// No description provided for @weekday7.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get weekday7;

  /// No description provided for @recordsCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 registro} other{{count} registros}}'**
  String recordsCount(int count);

  /// No description provided for @kmPerWeek.
  ///
  /// In es, this message translates to:
  /// **'~{km} km/sem'**
  String kmPerWeek(String km);

  /// No description provided for @usageHintTitle.
  ///
  /// In es, this message translates to:
  /// **'Estimación por uso'**
  String get usageHintTitle;

  /// No description provided for @usageHintWithReminder.
  ///
  /// In es, this message translates to:
  /// **'Cuando haya al menos una semana de lecturas de km, se va a estimar la fecha de cada servicio según cuánto usás el vehículo.'**
  String get usageHintWithReminder;

  /// No description provided for @usageHintWithoutReminder.
  ///
  /// In es, this message translates to:
  /// **'Activá el recordatorio de kilometraje (Editar vehículo) o cargá el km cada tanto, y se va a estimar la fecha de cada servicio según cuánto usás el vehículo.'**
  String get usageHintWithoutReminder;

  /// No description provided for @hiddenCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 mantenimiento oculto para este vehículo} other{{count} mantenimientos ocultos para este vehículo}}'**
  String hiddenCount(int count);

  /// No description provided for @hiddenTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantenimientos ocultos'**
  String get hiddenTitle;

  /// No description provided for @kmInvalid.
  ///
  /// In es, this message translates to:
  /// **'No se guardó: escribí solo el número de km.'**
  String get kmInvalid;

  /// No description provided for @kmLowerThanCurrent.
  ///
  /// In es, this message translates to:
  /// **'No se guardó: {km} km es menos que los {current} km ya registrados.'**
  String kmLowerThanCurrent(String km, String current);

  /// No description provided for @overrideHelp.
  ///
  /// In es, this message translates to:
  /// **'Intervalo sólo para {vehicle}. Dejalo vacío para usar el del tipo.'**
  String overrideHelp(String vehicle);

  /// No description provided for @everyKmLabel.
  ///
  /// In es, this message translates to:
  /// **'Cada cuántos km'**
  String get everyKmLabel;

  /// No description provided for @everyDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Cada cuántos días'**
  String get everyDaysLabel;

  /// No description provided for @fromType.
  ///
  /// In es, this message translates to:
  /// **'Del tipo: {value}'**
  String fromType(String value);

  /// No description provided for @fromTypeNoKm.
  ///
  /// In es, this message translates to:
  /// **'Del tipo: sin control por km'**
  String get fromTypeNoKm;

  /// No description provided for @fromTypeNoDays.
  ///
  /// In es, this message translates to:
  /// **'Del tipo: sin control por tiempo'**
  String get fromTypeNoDays;

  /// No description provided for @zeroDisables.
  ///
  /// In es, this message translates to:
  /// **'Poné 0 para no controlarlo por ese criterio.'**
  String get zeroDisables;

  /// No description provided for @statusOverdue.
  ///
  /// In es, this message translates to:
  /// **'VENCIDO'**
  String get statusOverdue;

  /// No description provided for @statusDueSoon.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO'**
  String get statusDueSoon;

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'SIN REGISTRO'**
  String get statusPending;

  /// No description provided for @statusOk.
  ///
  /// In es, this message translates to:
  /// **'AL DÍA'**
  String get statusOk;

  /// No description provided for @pendingRecordText.
  ///
  /// In es, this message translates to:
  /// **'Sin registro. Contando desde 0 km ya tocaba: cargá el último servicio que le hiciste para calcular el próximo.'**
  String get pendingRecordText;

  /// No description provided for @lastService.
  ///
  /// In es, this message translates to:
  /// **'Último: {date} · {km} km'**
  String lastService(String date, String km);

  /// No description provided for @firstServiceNoRecord.
  ///
  /// In es, this message translates to:
  /// **'Primer servicio (todavía sin registro)'**
  String get firstServiceNoRecord;

  /// No description provided for @kmOverdue.
  ///
  /// In es, this message translates to:
  /// **'{km} km vencido'**
  String kmOverdue(String km);

  /// No description provided for @kmRemainingNext.
  ///
  /// In es, this message translates to:
  /// **'{km} km restantes (próximo: {next} km)'**
  String kmRemainingNext(String km, String next);

  /// No description provided for @daysOverdue.
  ///
  /// In es, this message translates to:
  /// **'{days} días vencido'**
  String daysOverdue(String days);

  /// No description provided for @daysRemainingDate.
  ///
  /// In es, this message translates to:
  /// **'{days} días restantes ({date})'**
  String daysRemainingDate(String days, String date);

  /// No description provided for @usageAlreadyNear.
  ///
  /// In es, this message translates to:
  /// **'Por tu uso ya deberías estar cerca de los {km} km: actualizá el km'**
  String usageAlreadyNear(String km);

  /// No description provided for @usageTomorrow.
  ///
  /// In es, this message translates to:
  /// **'Por tu uso llegarías a los {km} km mañana'**
  String usageTomorrow(String km);

  /// No description provided for @usageInDays.
  ///
  /// In es, this message translates to:
  /// **'Por tu uso llegarías a los {km} km en ~{days} días (~{date})'**
  String usageInDays(String km, String days, String date);

  /// No description provided for @ownInterval.
  ///
  /// In es, this message translates to:
  /// **'Intervalo propio de este vehículo'**
  String get ownInterval;

  /// No description provided for @actionRegister.
  ///
  /// In es, this message translates to:
  /// **'Registrar servicio'**
  String get actionRegister;

  /// No description provided for @actionCustomize.
  ///
  /// In es, this message translates to:
  /// **'Personalizar intervalo'**
  String get actionCustomize;

  /// No description provided for @actionSchedule.
  ///
  /// In es, this message translates to:
  /// **'Programar turno'**
  String get actionSchedule;

  /// No description provided for @actionEditAppointment.
  ///
  /// In es, this message translates to:
  /// **'Editar turno'**
  String get actionEditAppointment;

  /// No description provided for @appointmentLine.
  ///
  /// In es, this message translates to:
  /// **'📅 Turno: {date}'**
  String appointmentLine(String date);

  /// No description provided for @appointmentLineShop.
  ///
  /// In es, this message translates to:
  /// **'📅 Turno: {date} en {shop}'**
  String appointmentLineShop(String date, String shop);

  /// No description provided for @appointmentPast.
  ///
  /// In es, this message translates to:
  /// **'El turno ya pasó: registrá el servicio o borralo.'**
  String get appointmentPast;

  /// No description provided for @appointmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Turno'**
  String get appointmentTitle;

  /// No description provided for @appointmentHelp.
  ///
  /// In es, this message translates to:
  /// **'Te avisa en la fecha que elijas. Lo que esté en el turno no usa el aviso automático por tiempo o km.'**
  String get appointmentHelp;

  /// No description provided for @appointmentsSection.
  ///
  /// In es, this message translates to:
  /// **'Turnos'**
  String get appointmentsSection;

  /// No description provided for @newAppointment.
  ///
  /// In es, this message translates to:
  /// **'Nuevo turno'**
  String get newAppointment;

  /// No description provided for @appointmentWhatToDo.
  ///
  /// In es, this message translates to:
  /// **'¿Qué se le va a hacer?'**
  String get appointmentWhatToDo;

  /// No description provided for @appointmentSuggested.
  ///
  /// In es, this message translates to:
  /// **'Ya vienen marcados los vencidos, los próximos y los que no tienen registro.'**
  String get appointmentSuggested;

  /// No description provided for @appointmentSelectAtLeastOne.
  ///
  /// In es, this message translates to:
  /// **'Elegí al menos un mantenimiento.'**
  String get appointmentSelectAtLeastOne;

  /// No description provided for @deleteAppointmentQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar este turno?'**
  String get deleteAppointmentQuestion;

  /// No description provided for @completeAppointment.
  ///
  /// In es, this message translates to:
  /// **'Registrar lo hecho'**
  String get completeAppointment;

  /// No description provided for @completeAppointmentTitle.
  ///
  /// In es, this message translates to:
  /// **'Registrar servicios del turno'**
  String get completeAppointmentTitle;

  /// No description provided for @completeAppointmentHelp.
  ///
  /// In es, this message translates to:
  /// **'Se crea un registro por cada mantenimiento tildado y el turno se cierra. Destildá lo que al final no se hizo.'**
  String get completeAppointmentHelp;

  /// No description provided for @costOptional.
  ///
  /// In es, this message translates to:
  /// **'Costo (opcional)'**
  String get costOptional;

  /// No description provided for @remindMe.
  ///
  /// In es, this message translates to:
  /// **'Avisarme'**
  String get remindMe;

  /// No description provided for @remindAtTime.
  ///
  /// In es, this message translates to:
  /// **'A la hora del turno'**
  String get remindAtTime;

  /// No description provided for @remindHourBefore.
  ///
  /// In es, this message translates to:
  /// **'1 hora antes'**
  String get remindHourBefore;

  /// No description provided for @remindDayBefore.
  ///
  /// In es, this message translates to:
  /// **'1 día antes'**
  String get remindDayBefore;

  /// No description provided for @appointmentDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar turno'**
  String get appointmentDelete;

  /// No description provided for @appointmentInPast.
  ///
  /// In es, this message translates to:
  /// **'Elegí una fecha y hora futuras.'**
  String get appointmentInPast;

  /// No description provided for @appointmentNotifTitle.
  ///
  /// In es, this message translates to:
  /// **'📅 Turno · {vehicle}'**
  String appointmentNotifTitle(String vehicle);

  /// No description provided for @appointmentNotifBody.
  ///
  /// In es, this message translates to:
  /// **'{when}: {items}'**
  String appointmentNotifBody(String when, String items);

  /// No description provided for @appointmentNotifBodyShop.
  ///
  /// In es, this message translates to:
  /// **'{when} en {shop}: {items}'**
  String appointmentNotifBodyShop(String when, String shop, String items);

  /// No description provided for @noActiveMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Este tipo de vehículo no tiene mantenimientos activos. Agregalos en Configuración → Tipos de vehículo.'**
  String get noActiveMaintenance;

  /// No description provided for @mechanicHint.
  ///
  /// In es, this message translates to:
  /// **'Nombre del taller o mecánico'**
  String get mechanicHint;

  /// No description provided for @pickFromList.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la lista'**
  String get pickFromList;

  /// No description provided for @productsHint.
  ///
  /// In es, this message translates to:
  /// **'Shell 10W-40, Filtro Fram...'**
  String get productsHint;

  /// No description provided for @notesHint.
  ///
  /// In es, this message translates to:
  /// **'Observaciones adicionales...'**
  String get notesHint;

  /// No description provided for @catalogsSection.
  ///
  /// In es, this message translates to:
  /// **'Catálogos'**
  String get catalogsSection;

  /// No description provided for @vehicleTypesAndMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Tipos de vehículo y mantenimientos'**
  String get vehicleTypesAndMaintenance;

  /// No description provided for @vehicleTypesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Qué se controla en cada tipo y cada cuánto'**
  String get vehicleTypesSubtitle;

  /// No description provided for @mechanicsTitle.
  ///
  /// In es, this message translates to:
  /// **'Talleres y mecánicos'**
  String get mechanicsTitle;

  /// No description provided for @maintenanceRemindersSection.
  ///
  /// In es, this message translates to:
  /// **'Avisos de mantenimiento'**
  String get maintenanceRemindersSection;

  /// No description provided for @remindBeforeService.
  ///
  /// In es, this message translates to:
  /// **'Avisar antes de cada servicio'**
  String get remindBeforeService;

  /// No description provided for @remindBeforeServiceSub.
  ///
  /// In es, this message translates to:
  /// **'Por fecha o por el uso estimado, lo que llegue primero'**
  String get remindBeforeServiceSub;

  /// No description provided for @advance.
  ///
  /// In es, this message translates to:
  /// **'Anticipación'**
  String get advance;

  /// No description provided for @sameDay.
  ///
  /// In es, this message translates to:
  /// **'El mismo día'**
  String get sameDay;

  /// No description provided for @daysBefore.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 día antes} other{{count} días antes}}'**
  String daysBefore(int count);

  /// No description provided for @howManyDaysBefore.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántos días antes avisar?'**
  String get howManyDaysBefore;

  /// No description provided for @reminderTime.
  ///
  /// In es, this message translates to:
  /// **'Hora del aviso'**
  String get reminderTime;

  /// No description provided for @dueSoonSection.
  ///
  /// In es, this message translates to:
  /// **'Cuándo un servicio pasa a PRÓXIMO'**
  String get dueSoonSection;

  /// No description provided for @lessThan.
  ///
  /// In es, this message translates to:
  /// **'Faltan menos de'**
  String get lessThan;

  /// No description provided for @orLessThan.
  ///
  /// In es, this message translates to:
  /// **'o faltan menos de'**
  String get orLessThan;

  /// No description provided for @kmAdvance.
  ///
  /// In es, this message translates to:
  /// **'Km de anticipación'**
  String get kmAdvance;

  /// No description provided for @daysAdvance.
  ///
  /// In es, this message translates to:
  /// **'Días de anticipación'**
  String get daysAdvance;

  /// No description provided for @dataSection.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get dataSection;

  /// No description provided for @exportBackup.
  ///
  /// In es, this message translates to:
  /// **'Exportar backup'**
  String get exportBackup;

  /// No description provided for @exportBackupSub.
  ///
  /// In es, this message translates to:
  /// **'Un archivo con todo, para guardarlo o pasarlo a otro teléfono'**
  String get exportBackupSub;

  /// No description provided for @restoreBackup.
  ///
  /// In es, this message translates to:
  /// **'Restaurar backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupSub.
  ///
  /// In es, this message translates to:
  /// **'Reemplaza los datos actuales'**
  String get restoreBackupSub;

  /// No description provided for @backupError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo generar el backup.'**
  String get backupError;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar este backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmVehicles.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Trae 1 vehículo.} other{Trae {count} vehículos.}}'**
  String restoreConfirmVehicles(int count);

  /// No description provided for @restoreConfirmWarning.
  ///
  /// In es, this message translates to:
  /// **'Se REEMPLAZAN todos los datos actuales de la app: lo que no esté en el backup se pierde.'**
  String get restoreConfirmWarning;

  /// No description provided for @replaceAll.
  ///
  /// In es, this message translates to:
  /// **'Reemplazar todo'**
  String get replaceAll;

  /// No description provided for @restoreDone.
  ///
  /// In es, this message translates to:
  /// **'Backup restaurado.'**
  String get restoreDone;

  /// No description provided for @restoreFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo restaurar el backup. Los datos anteriores no se modificaron.'**
  String get restoreFailed;

  /// No description provided for @backupInvalidFile.
  ///
  /// In es, this message translates to:
  /// **'El archivo no es un backup válido.'**
  String get backupInvalidFile;

  /// No description provided for @backupNotOurs.
  ///
  /// In es, this message translates to:
  /// **'El archivo no es un backup de Mis Vehículos.'**
  String get backupNotOurs;

  /// No description provided for @backupTooNew.
  ///
  /// In es, this message translates to:
  /// **'El backup es de una versión más nueva de la app. Actualizala primero.'**
  String get backupTooNew;

  /// No description provided for @backupShareSubject.
  ///
  /// In es, this message translates to:
  /// **'Backup Mis Vehículos'**
  String get backupShareSubject;

  /// No description provided for @updateNotifTitle.
  ///
  /// In es, this message translates to:
  /// **'Hay una versión nueva de Mis Vehículos'**
  String get updateNotifTitle;

  /// No description provided for @updateNotifBody.
  ///
  /// In es, this message translates to:
  /// **'La versión {version} está lista. Tocá para descargarla.'**
  String updateNotifBody(String version);

  /// No description provided for @updateChannelName.
  ///
  /// In es, this message translates to:
  /// **'Actualizaciones'**
  String get updateChannelName;

  /// No description provided for @updateChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Aviso cuando hay una versión nueva de la app'**
  String get updateChannelDescription;

  /// No description provided for @updateDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} disponible'**
  String updateDialogTitle(String version);

  /// No description provided for @updateDialogBody.
  ///
  /// In es, this message translates to:
  /// **'Tenés la {current}. Descargá el APK e instalalo encima: no se pierde ningún dato.'**
  String updateDialogBody(String current);

  /// No description provided for @updateDownload.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get updateDownload;

  /// No description provided for @updateLater.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get updateLater;

  /// No description provided for @checkUpdates.
  ///
  /// In es, this message translates to:
  /// **'Buscar actualizaciones'**
  String get checkUpdates;

  /// No description provided for @checkingUpdates.
  ///
  /// In es, this message translates to:
  /// **'Buscando…'**
  String get checkingUpdates;

  /// No description provided for @upToDate.
  ///
  /// In es, this message translates to:
  /// **'Tenés la última versión'**
  String get upToDate;

  /// No description provided for @updateAvailableShort.
  ///
  /// In es, this message translates to:
  /// **'Versión {version} disponible, tocá para descargar'**
  String updateAvailableShort(String version);

  /// No description provided for @updateCheckFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo consultar. Revisá la conexión a internet.'**
  String get updateCheckFailed;

  /// No description provided for @updateOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el link de descarga'**
  String get updateOpenError;

  /// No description provided for @aboutSection.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get aboutSection;

  /// No description provided for @developedBy.
  ///
  /// In es, this message translates to:
  /// **'Desarrollada por'**
  String get developedBy;

  /// No description provided for @instagramOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir Instagram.'**
  String get instagramOpenError;

  /// No description provided for @storage.
  ///
  /// In es, this message translates to:
  /// **'Almacenamiento'**
  String get storage;

  /// No description provided for @storageText.
  ///
  /// In es, this message translates to:
  /// **'Todos los datos se guardan sólo en tu teléfono. La app sólo se conecta a internet para ver si hay una versión nueva.'**
  String get storageText;

  /// No description provided for @vehicleTypesTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipos de vehículo'**
  String get vehicleTypesTitle;

  /// No description provided for @vehicleTypesHelp.
  ///
  /// In es, this message translates to:
  /// **'Cada tipo tiene su propia lista de mantenimientos. Tocá uno para configurarlos.'**
  String get vehicleTypesHelp;

  /// No description provided for @activeMaintenanceCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin mantenimientos activos} =1{1 mantenimiento activo} other{{count} mantenimientos activos}}'**
  String activeMaintenanceCount(int count);

  /// No description provided for @newType.
  ///
  /// In es, this message translates to:
  /// **'Nuevo tipo'**
  String get newType;

  /// No description provided for @editType.
  ///
  /// In es, this message translates to:
  /// **'Editar tipo'**
  String get editType;

  /// No description provided for @typeNameHint.
  ///
  /// In es, this message translates to:
  /// **'Camión, Cuatriciclo, Lancha...'**
  String get typeNameHint;

  /// No description provided for @cannotDelete.
  ///
  /// In es, this message translates to:
  /// **'No se puede eliminar'**
  String get cannotDelete;

  /// No description provided for @typeInUse.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Hay 1 vehículo de tipo \"{name}\". Cambiale el tipo o eliminalo primero.} other{Hay {count} vehículos de tipo \"{name}\". Cambiales el tipo o eliminalos primero.}}'**
  String typeInUse(int count, String name);

  /// No description provided for @deleteQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"?'**
  String deleteQuestion(String name);

  /// No description provided for @deleteTypeAlsoMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Se eliminan también sus mantenimientos.'**
  String get deleteTypeAlsoMaintenance;

  /// No description provided for @copyFromOtherType.
  ///
  /// In es, this message translates to:
  /// **'Copiar de otro tipo'**
  String get copyFromOtherType;

  /// No description provided for @copyMaintenanceFrom.
  ///
  /// In es, this message translates to:
  /// **'Copiar mantenimientos de…'**
  String get copyMaintenanceFrom;

  /// No description provided for @noMaintenanceForType.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay mantenimientos para este tipo.'**
  String get noMaintenanceForType;

  /// No description provided for @newItem.
  ///
  /// In es, this message translates to:
  /// **'Nuevo'**
  String get newItem;

  /// No description provided for @newMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Nuevo mantenimiento'**
  String get newMaintenance;

  /// No description provided for @noInterval.
  ///
  /// In es, this message translates to:
  /// **'Sin intervalo (sólo registro)'**
  String get noInterval;

  /// No description provided for @everyKm.
  ///
  /// In es, this message translates to:
  /// **'cada {km} km'**
  String everyKm(String km);

  /// No description provided for @everyDays.
  ///
  /// In es, this message translates to:
  /// **'cada {days} días'**
  String everyDays(String days);

  /// No description provided for @orSeparator.
  ///
  /// In es, this message translates to:
  /// **' o '**
  String get orSeparator;

  /// No description provided for @whicheverFirst.
  ///
  /// In es, this message translates to:
  /// **'{parts} · el que llegue primero'**
  String whicheverFirst(String parts);

  /// No description provided for @hasHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Tiene historial'**
  String get hasHistoryTitle;

  /// No description provided for @hasHistoryBody.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{\"{name}\" tiene 1 registro.} other{\"{name}\" tiene {count} registros.}} Si lo eliminás, ese historial queda sin nombre. ¿Preferís desactivarlo? Deja de aparecer en recomendaciones y al cargar, pero el historial se conserva.'**
  String hasHistoryBody(int count, String name);

  /// No description provided for @deleteAnyway.
  ///
  /// In es, this message translates to:
  /// **'Eliminar igual'**
  String get deleteAnyway;

  /// No description provided for @deactivate.
  ///
  /// In es, this message translates to:
  /// **'Desactivar'**
  String get deactivate;

  /// No description provided for @descriptionOptional.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get descriptionOptional;

  /// No description provided for @intervalLabel.
  ///
  /// In es, this message translates to:
  /// **'Intervalo'**
  String get intervalLabel;

  /// No description provided for @intervalHelp.
  ///
  /// In es, this message translates to:
  /// **'Toca por km o por tiempo, lo que llegue primero. Dejá vacío el que no se controle; con los dos vacíos sólo sirve para registrar.'**
  String get intervalHelp;

  /// No description provided for @everyLabel.
  ///
  /// In es, this message translates to:
  /// **'Cada'**
  String get everyLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get priorityLabel;

  /// No description provided for @unknownMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento eliminado'**
  String get unknownMaintenance;

  /// No description provided for @mechanicsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay talleres. Agregá los que usás, o se suman solos cuando escribís uno nuevo al registrar un servicio.'**
  String get mechanicsEmpty;

  /// No description provided for @deleteMechanicBody.
  ///
  /// In es, this message translates to:
  /// **'Sólo se saca de la lista: los servicios ya registrados conservan el nombre del taller.'**
  String get deleteMechanicBody;

  /// No description provided for @callError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el teléfono.'**
  String get callError;

  /// No description provided for @newMechanic.
  ///
  /// In es, this message translates to:
  /// **'Nuevo taller'**
  String get newMechanic;

  /// No description provided for @editMechanic.
  ///
  /// In es, this message translates to:
  /// **'Editar taller'**
  String get editMechanic;

  /// No description provided for @phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get address;

  /// No description provided for @notesLabel.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get notesLabel;

  /// No description provided for @kmPromptTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántos km tiene {vehicle}?'**
  String kmPromptTitle(String vehicle);

  /// No description provided for @kmPromptBody.
  ///
  /// In es, this message translates to:
  /// **'Cargá el kilometraje actual para estimar el próximo mantenimiento.'**
  String get kmPromptBody;

  /// No description provided for @kmActionLabel.
  ///
  /// In es, this message translates to:
  /// **'Cargar km'**
  String get kmActionLabel;

  /// No description provided for @kmInputLabel.
  ///
  /// In es, this message translates to:
  /// **'Km actuales (solo números)'**
  String get kmInputLabel;

  /// No description provided for @kmSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado: {km} km.'**
  String kmSaved(String km);

  /// No description provided for @kmNotValid.
  ///
  /// In es, this message translates to:
  /// **'No se guardó: \"{text}\" no es un km válido. Escribí solo el número, por ejemplo 45000.'**
  String kmNotValid(String text);

  /// No description provided for @kmVehicleGone.
  ///
  /// In es, this message translates to:
  /// **'No se guardó: el vehículo ya no existe.'**
  String get kmVehicleGone;

  /// No description provided for @genericVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get genericVehicle;

  /// No description provided for @channelKm.
  ///
  /// In es, this message translates to:
  /// **'Kilometraje'**
  String get channelKm;

  /// No description provided for @channelKmDesc.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio semanal para cargar el km'**
  String get channelKmDesc;

  /// No description provided for @channelMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento de vehículos'**
  String get channelMaintenance;

  /// No description provided for @channelMaintenanceDesc.
  ///
  /// In es, this message translates to:
  /// **'Avisos antes de que toque un mantenimiento'**
  String get channelMaintenanceDesc;

  /// No description provided for @maintenanceDueDate.
  ///
  /// In es, this message translates to:
  /// **'Le toca el {date}.'**
  String maintenanceDueDate(String date);

  /// No description provided for @maintenanceDueUsage.
  ///
  /// In es, this message translates to:
  /// **'Por tu uso llegarías a los {km} km cerca del {date}.'**
  String maintenanceDueUsage(String km, String date);

  /// No description provided for @pdfTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de mantenimiento'**
  String get pdfTitle;

  /// No description provided for @pdfVehicle.
  ///
  /// In es, this message translates to:
  /// **'Vehículo'**
  String get pdfVehicle;

  /// No description provided for @totalCostLabel.
  ///
  /// In es, this message translates to:
  /// **'Costo total'**
  String get totalCostLabel;

  /// No description provided for @recordsTitle.
  ///
  /// In es, this message translates to:
  /// **'Registros ({count})'**
  String recordsTitle(String count);

  /// No description provided for @noRecords.
  ///
  /// In es, this message translates to:
  /// **'Sin registros'**
  String get noRecords;

  /// No description provided for @generatedOn.
  ///
  /// In es, this message translates to:
  /// **'Generado el {date} con Mis Vehículos'**
  String generatedOn(String date);

  /// No description provided for @fileSuffixMaintenance.
  ///
  /// In es, this message translates to:
  /// **'mantenimiento'**
  String get fileSuffixMaintenance;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
