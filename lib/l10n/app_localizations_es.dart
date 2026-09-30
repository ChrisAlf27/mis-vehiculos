// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Mis Vehículos';

  @override
  String get vehicles => 'Vehículos';

  @override
  String get maintenance => 'Mantenimiento';

  @override
  String get history => 'Historial';

  @override
  String get settings => 'Configuración';

  @override
  String get addVehicle => 'Agregar vehículo';

  @override
  String get editVehicle => 'Editar vehículo';

  @override
  String get deleteVehicle => 'Eliminar vehículo';

  @override
  String get addMaintenance => 'Registrar mantenimiento';

  @override
  String get editMaintenance => 'Editar mantenimiento';

  @override
  String get deleteMaintenance => 'Eliminar registro';

  @override
  String get vehicleName => 'Nombre del vehículo';

  @override
  String get vehicleType => 'Tipo de vehículo';

  @override
  String get car => 'Auto / Camioneta';

  @override
  String get motorcycle => 'Moto';

  @override
  String get brand => 'Marca';

  @override
  String get model => 'Modelo';

  @override
  String get year => 'Año';

  @override
  String get licensePlate => 'Patente';

  @override
  String get currentKm => 'Kilometraje actual';

  @override
  String get maintenanceType => 'Tipo de mantenimiento';

  @override
  String get date => 'Fecha';

  @override
  String get kmAtService => 'Km al momento del servicio';

  @override
  String get cost => 'Costo';

  @override
  String get mechanic => 'Taller / Mecánico';

  @override
  String get productsUsed => 'Productos utilizados';

  @override
  String get notes => 'Notas / Observaciones';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get edit => 'Editar';

  @override
  String get close => 'Cerrar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get understood => 'Entendido';

  @override
  String get show => 'Mostrar';

  @override
  String get hide => 'Ocultar';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get iconLabel => 'Ícono';

  @override
  String get emojiHint => 'Tocá uno o escribí cualquier emoji.';

  @override
  String get confirmDeleteVehicle =>
      '¿Eliminar este vehículo y todo su historial?';

  @override
  String get confirmDeleteMaintenance =>
      '¿Eliminar este registro de mantenimiento?';

  @override
  String get noVehicles =>
      'No hay vehículos registrados.\nTocá + para agregar uno.';

  @override
  String get noHistory => 'No hay registros de mantenimiento.';

  @override
  String get noRecommendations =>
      'No hay recomendaciones pendientes.\n¡Todo al día!';

  @override
  String get exportCSV => 'Exportar CSV';

  @override
  String get exportPDF => 'Exportar PDF';

  @override
  String get exportError => 'Error al exportar';

  @override
  String get language => 'Idioma';

  @override
  String get spanish => 'Español';

  @override
  String get english => 'Inglés';

  @override
  String get fieldRequired => 'Este campo es obligatorio';

  @override
  String get invalidNumber => 'Ingresá un número válido';

  @override
  String get invalidYear => 'Año inválido';

  @override
  String get updateKm => 'Actualizar kilometraje';

  @override
  String get maintenanceHistory => 'Historial de mantenimiento';

  @override
  String get recommendations => 'Recomendaciones';

  @override
  String get high => 'Alta';

  @override
  String get medium => 'Media';

  @override
  String get low => 'Baja';

  @override
  String get unitKm => 'km';

  @override
  String get unitDays => 'días';

  @override
  String get hintVehicleName => 'Mi auto, Moto del trabajo...';

  @override
  String get hintBrand => 'Toyota, Honda, Yamaha...';

  @override
  String get hintModel => 'Corolla, CBR500, MT-03...';

  @override
  String get hintPlate => 'ABC 123';

  @override
  String get chooseVehicleType => 'Elegí un tipo de vehículo.';

  @override
  String get noVehicleTypes =>
      'No hay tipos de vehículo. Creá uno en Configuración → Tipos de vehículo.';

  @override
  String get kmReminderTitle => 'Recordatorio de kilometraje';

  @override
  String get kmReminderSubtitle =>
      'Una notificación semanal te pregunta el km actual para estimar cuándo toca cada mantenimiento.';

  @override
  String get dayLabel => 'Día';

  @override
  String get timeLabel => 'Hora';

  @override
  String get notificationPermissionDenied =>
      'Sin permiso de notificaciones los avisos no van a aparecer. Habilitalo en Ajustes del sistema.';

  @override
  String get weekday1 => 'Lunes';

  @override
  String get weekday2 => 'Martes';

  @override
  String get weekday3 => 'Miércoles';

  @override
  String get weekday4 => 'Jueves';

  @override
  String get weekday5 => 'Viernes';

  @override
  String get weekday6 => 'Sábado';

  @override
  String get weekday7 => 'Domingo';

  @override
  String recordsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros',
      one: '1 registro',
    );
    return '$_temp0';
  }

  @override
  String kmPerWeek(String km) {
    return '~$km km/sem';
  }

  @override
  String get usageHintTitle => 'Estimación por uso';

  @override
  String get usageHintWithReminder =>
      'Cuando haya al menos una semana de lecturas de km, se va a estimar la fecha de cada servicio según cuánto usás el vehículo.';

  @override
  String get usageHintWithoutReminder =>
      'Activá el recordatorio de kilometraje (Editar vehículo) o cargá el km cada tanto, y se va a estimar la fecha de cada servicio según cuánto usás el vehículo.';

  @override
  String hiddenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mantenimientos ocultos para este vehículo',
      one: '1 mantenimiento oculto para este vehículo',
    );
    return '$_temp0';
  }

  @override
  String get hiddenTitle => 'Mantenimientos ocultos';

  @override
  String get kmInvalid => 'No se guardó: escribí solo el número de km.';

  @override
  String kmLowerThanCurrent(String km, String current) {
    return 'No se guardó: $km km es menos que los $current km ya registrados.';
  }

  @override
  String overrideHelp(String vehicle) {
    return 'Intervalo sólo para $vehicle. Dejalo vacío para usar el del tipo.';
  }

  @override
  String get everyKmLabel => 'Cada cuántos km';

  @override
  String get everyDaysLabel => 'Cada cuántos días';

  @override
  String fromType(String value) {
    return 'Del tipo: $value';
  }

  @override
  String get fromTypeNoKm => 'Del tipo: sin control por km';

  @override
  String get fromTypeNoDays => 'Del tipo: sin control por tiempo';

  @override
  String get zeroDisables => 'Poné 0 para no controlarlo por ese criterio.';

  @override
  String get statusOverdue => 'VENCIDO';

  @override
  String get statusDueSoon => 'PRÓXIMO';

  @override
  String get statusPending => 'SIN REGISTRO';

  @override
  String get statusOk => 'AL DÍA';

  @override
  String get pendingRecordText =>
      'Sin registro. Contando desde 0 km ya tocaba: cargá el último servicio que le hiciste para calcular el próximo.';

  @override
  String lastService(String date, String km) {
    return 'Último: $date · $km km';
  }

  @override
  String get firstServiceNoRecord => 'Primer servicio (todavía sin registro)';

  @override
  String kmOverdue(String km) {
    return '$km km vencido';
  }

  @override
  String kmRemainingNext(String km, String next) {
    return '$km km restantes (próximo: $next km)';
  }

  @override
  String daysOverdue(String days) {
    return '$days días vencido';
  }

  @override
  String daysRemainingDate(String days, String date) {
    return '$days días restantes ($date)';
  }

  @override
  String usageAlreadyNear(String km) {
    return 'Por tu uso ya deberías estar cerca de los $km km: actualizá el km';
  }

  @override
  String usageTomorrow(String km) {
    return 'Por tu uso llegarías a los $km km mañana';
  }

  @override
  String usageInDays(String km, String days, String date) {
    return 'Por tu uso llegarías a los $km km en ~$days días (~$date)';
  }

  @override
  String get ownInterval => 'Intervalo propio de este vehículo';

  @override
  String get actionRegister => 'Registrar servicio';

  @override
  String get actionCustomize => 'Personalizar intervalo';

  @override
  String get actionSchedule => 'Programar turno';

  @override
  String get actionEditAppointment => 'Editar turno';

  @override
  String appointmentLine(String date) {
    return '📅 Turno: $date';
  }

  @override
  String appointmentLineShop(String date, String shop) {
    return '📅 Turno: $date en $shop';
  }

  @override
  String get appointmentPast =>
      'El turno ya pasó: registrá el servicio o borralo.';

  @override
  String get appointmentTitle => 'Turno';

  @override
  String get appointmentHelp =>
      'Te avisa en la fecha que elijas. Lo que esté en el turno no usa el aviso automático por tiempo o km.';

  @override
  String get appointmentsSection => 'Turnos';

  @override
  String get newAppointment => 'Nuevo turno';

  @override
  String get appointmentWhatToDo => '¿Qué se le va a hacer?';

  @override
  String get appointmentSuggested =>
      'Ya vienen marcados los vencidos, los próximos y los que no tienen registro.';

  @override
  String get appointmentSelectAtLeastOne => 'Elegí al menos un mantenimiento.';

  @override
  String get deleteAppointmentQuestion => '¿Borrar este turno?';

  @override
  String get completeAppointment => 'Registrar lo hecho';

  @override
  String get completeAppointmentTitle => 'Registrar servicios del turno';

  @override
  String get completeAppointmentHelp =>
      'Se crea un registro por cada mantenimiento tildado y el turno se cierra. Destildá lo que al final no se hizo.';

  @override
  String get costOptional => 'Costo (opcional)';

  @override
  String get remindMe => 'Avisarme';

  @override
  String get remindAtTime => 'A la hora del turno';

  @override
  String get remindHourBefore => '1 hora antes';

  @override
  String get remindDayBefore => '1 día antes';

  @override
  String get appointmentDelete => 'Borrar turno';

  @override
  String get appointmentInPast => 'Elegí una fecha y hora futuras.';

  @override
  String appointmentNotifTitle(String vehicle) {
    return '📅 Turno · $vehicle';
  }

  @override
  String appointmentNotifBody(String when, String items) {
    return '$when: $items';
  }

  @override
  String appointmentNotifBodyShop(String when, String shop, String items) {
    return '$when en $shop: $items';
  }

  @override
  String get noActiveMaintenance =>
      'Este tipo de vehículo no tiene mantenimientos activos. Agregalos en Configuración → Tipos de vehículo.';

  @override
  String get mechanicHint => 'Nombre del taller o mecánico';

  @override
  String get pickFromList => 'Elegir de la lista';

  @override
  String get productsHint => 'Shell 10W-40, Filtro Fram...';

  @override
  String get notesHint => 'Observaciones adicionales...';

  @override
  String get catalogsSection => 'Catálogos';

  @override
  String get vehicleTypesAndMaintenance => 'Tipos de vehículo y mantenimientos';

  @override
  String get vehicleTypesSubtitle =>
      'Qué se controla en cada tipo y cada cuánto';

  @override
  String get mechanicsTitle => 'Talleres y mecánicos';

  @override
  String get maintenanceRemindersSection => 'Avisos de mantenimiento';

  @override
  String get remindBeforeService => 'Avisar antes de cada servicio';

  @override
  String get remindBeforeServiceSub =>
      'Por fecha o por el uso estimado, lo que llegue primero';

  @override
  String get advance => 'Anticipación';

  @override
  String get sameDay => 'El mismo día';

  @override
  String daysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días antes',
      one: '1 día antes',
    );
    return '$_temp0';
  }

  @override
  String get howManyDaysBefore => '¿Cuántos días antes avisar?';

  @override
  String get reminderTime => 'Hora del aviso';

  @override
  String get dueSoonSection => 'Cuándo un servicio pasa a PRÓXIMO';

  @override
  String get lessThan => 'Faltan menos de';

  @override
  String get orLessThan => 'o faltan menos de';

  @override
  String get kmAdvance => 'Km de anticipación';

  @override
  String get daysAdvance => 'Días de anticipación';

  @override
  String get dataSection => 'Datos';

  @override
  String get exportBackup => 'Exportar backup';

  @override
  String get exportBackupSub =>
      'Un archivo con todo, para guardarlo o pasarlo a otro teléfono';

  @override
  String get restoreBackup => 'Restaurar backup';

  @override
  String get restoreBackupSub => 'Reemplaza los datos actuales';

  @override
  String get backupError => 'No se pudo generar el backup.';

  @override
  String get restoreConfirmTitle => '¿Restaurar este backup?';

  @override
  String restoreConfirmVehicles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trae $count vehículos.',
      one: 'Trae 1 vehículo.',
    );
    return '$_temp0';
  }

  @override
  String get restoreConfirmWarning =>
      'Se REEMPLAZAN todos los datos actuales de la app: lo que no esté en el backup se pierde.';

  @override
  String get replaceAll => 'Reemplazar todo';

  @override
  String get restoreDone => 'Backup restaurado.';

  @override
  String get restoreFailed =>
      'No se pudo restaurar el backup. Los datos anteriores no se modificaron.';

  @override
  String get backupInvalidFile => 'El archivo no es un backup válido.';

  @override
  String get backupNotOurs => 'El archivo no es un backup de Mis Vehículos.';

  @override
  String get backupTooNew =>
      'El backup es de una versión más nueva de la app. Actualizala primero.';

  @override
  String get backupShareSubject => 'Backup Mis Vehículos';

  @override
  String get updateNotifTitle => 'Hay una versión nueva de Mis Vehículos';

  @override
  String updateNotifBody(String version) {
    return 'La versión $version está lista. Tocá para descargarla.';
  }

  @override
  String get updateChannelName => 'Actualizaciones';

  @override
  String get updateChannelDescription =>
      'Aviso cuando hay una versión nueva de la app';

  @override
  String updateDialogTitle(String version) {
    return 'Versión $version disponible';
  }

  @override
  String updateDialogBody(String current) {
    return 'Tenés la $current. Descargá el APK e instalalo encima: no se pierde ningún dato.';
  }

  @override
  String get updateDownload => 'Descargar';

  @override
  String get updateLater => 'Más tarde';

  @override
  String get checkUpdates => 'Buscar actualizaciones';

  @override
  String get checkingUpdates => 'Buscando…';

  @override
  String get upToDate => 'Tenés la última versión';

  @override
  String updateAvailableShort(String version) {
    return 'Versión $version disponible, tocá para descargar';
  }

  @override
  String get updateCheckFailed =>
      'No se pudo consultar. Revisá la conexión a internet.';

  @override
  String get updateOpenError => 'No se pudo abrir el link de descarga';

  @override
  String get aboutSection => 'Acerca de';

  @override
  String get developedBy => 'Desarrollada por';

  @override
  String get instagramOpenError => 'No se pudo abrir Instagram.';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get storageText =>
      'Todos los datos se guardan sólo en tu teléfono. La app sólo se conecta a internet para ver si hay una versión nueva.';

  @override
  String get vehicleTypesTitle => 'Tipos de vehículo';

  @override
  String get vehicleTypesHelp =>
      'Cada tipo tiene su propia lista de mantenimientos. Tocá uno para configurarlos.';

  @override
  String activeMaintenanceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mantenimientos activos',
      one: '1 mantenimiento activo',
      zero: 'Sin mantenimientos activos',
    );
    return '$_temp0';
  }

  @override
  String get newType => 'Nuevo tipo';

  @override
  String get editType => 'Editar tipo';

  @override
  String get typeNameHint => 'Camión, Cuatriciclo, Lancha...';

  @override
  String get cannotDelete => 'No se puede eliminar';

  @override
  String typeInUse(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Hay $count vehículos de tipo \"$name\". Cambiales el tipo o eliminalos primero.',
      one:
          'Hay 1 vehículo de tipo \"$name\". Cambiale el tipo o eliminalo primero.',
    );
    return '$_temp0';
  }

  @override
  String deleteQuestion(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get deleteTypeAlsoMaintenance =>
      'Se eliminan también sus mantenimientos.';

  @override
  String get copyFromOtherType => 'Copiar de otro tipo';

  @override
  String get copyMaintenanceFrom => 'Copiar mantenimientos de…';

  @override
  String get noMaintenanceForType =>
      'Todavía no hay mantenimientos para este tipo.';

  @override
  String get newItem => 'Nuevo';

  @override
  String get newMaintenance => 'Nuevo mantenimiento';

  @override
  String get noInterval => 'Sin intervalo (sólo registro)';

  @override
  String everyKm(String km) {
    return 'cada $km km';
  }

  @override
  String everyDays(String days) {
    return 'cada $days días';
  }

  @override
  String get orSeparator => ' o ';

  @override
  String whicheverFirst(String parts) {
    return '$parts · el que llegue primero';
  }

  @override
  String get hasHistoryTitle => 'Tiene historial';

  @override
  String hasHistoryBody(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '\"$name\" tiene $count registros.',
      one: '\"$name\" tiene 1 registro.',
    );
    return '$_temp0 Si lo eliminás, ese historial queda sin nombre. ¿Preferís desactivarlo? Deja de aparecer en recomendaciones y al cargar, pero el historial se conserva.';
  }

  @override
  String get deleteAnyway => 'Eliminar igual';

  @override
  String get deactivate => 'Desactivar';

  @override
  String get descriptionOptional => 'Descripción (opcional)';

  @override
  String get intervalLabel => 'Intervalo';

  @override
  String get intervalHelp =>
      'Toca por km o por tiempo, lo que llegue primero. Dejá vacío el que no se controle; con los dos vacíos sólo sirve para registrar.';

  @override
  String get everyLabel => 'Cada';

  @override
  String get priorityLabel => 'Prioridad';

  @override
  String get unknownMaintenance => 'Mantenimiento eliminado';

  @override
  String get mechanicsEmpty =>
      'Todavía no hay talleres. Agregá los que usás, o se suman solos cuando escribís uno nuevo al registrar un servicio.';

  @override
  String get deleteMechanicBody =>
      'Sólo se saca de la lista: los servicios ya registrados conservan el nombre del taller.';

  @override
  String get callError => 'No se pudo abrir el teléfono.';

  @override
  String get newMechanic => 'Nuevo taller';

  @override
  String get editMechanic => 'Editar taller';

  @override
  String get phone => 'Teléfono';

  @override
  String get address => 'Dirección';

  @override
  String get notesLabel => 'Notas';

  @override
  String kmPromptTitle(String vehicle) {
    return '¿Cuántos km tiene $vehicle?';
  }

  @override
  String get kmPromptBody =>
      'Cargá el kilometraje actual para estimar el próximo mantenimiento.';

  @override
  String get kmActionLabel => 'Cargar km';

  @override
  String get kmInputLabel => 'Km actuales (solo números)';

  @override
  String kmSaved(String km) {
    return 'Guardado: $km km.';
  }

  @override
  String kmNotValid(String text) {
    return 'No se guardó: \"$text\" no es un km válido. Escribí solo el número, por ejemplo 45000.';
  }

  @override
  String get kmVehicleGone => 'No se guardó: el vehículo ya no existe.';

  @override
  String get genericVehicle => 'Vehículo';

  @override
  String get channelKm => 'Kilometraje';

  @override
  String get channelKmDesc => 'Recordatorio semanal para cargar el km';

  @override
  String get channelMaintenance => 'Mantenimiento de vehículos';

  @override
  String get channelMaintenanceDesc =>
      'Avisos antes de que toque un mantenimiento';

  @override
  String maintenanceDueDate(String date) {
    return 'Le toca el $date.';
  }

  @override
  String maintenanceDueUsage(String km, String date) {
    return 'Por tu uso llegarías a los $km km cerca del $date.';
  }

  @override
  String get pdfTitle => 'Historial de mantenimiento';

  @override
  String get pdfVehicle => 'Vehículo';

  @override
  String get totalCostLabel => 'Costo total';

  @override
  String recordsTitle(String count) {
    return 'Registros ($count)';
  }

  @override
  String get noRecords => 'Sin registros';

  @override
  String generatedOn(String date) {
    return 'Generado el $date con Mis Vehículos';
  }

  @override
  String get fileSuffixMaintenance => 'mantenimiento';
}
