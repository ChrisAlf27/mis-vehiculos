# 🚗 Mis Vehículos

App para Android que lleva el mantenimiento de tus autos y motos: qué le hiciste, cuándo y a qué kilometraje, y qué le toca después.

## ⬇️ Descargar

**[Descargar la última versión (APK)](https://github.com/ChrisAlf27/mis-vehiculos/releases/latest)**

1. Abrí el link desde el teléfono y descargá el archivo `MisVehiculos-x.y.z.apk`.
2. Abrilo. Si Android lo pide, permití instalar apps de esa fuente (el navegador o el administrador de archivos).
3. Listo. Para actualizar, hacés lo mismo con la versión nueva: se instala encima y **no se pierde ningún dato**.

La app te avisa sola cuando hay una versión nueva, y también podés buscarla en *Ajustes → Acerca de → Buscar actualizaciones*.

Requiere Android 7.0 o más nuevo.

## ✨ Qué hace

- **Vehículos y tipos configurables**: autos, motos o lo que quieras, cada uno con su propia lista de mantenimientos.
- **Próximo servicio por km y por fecha**, lo que llegue primero, con intervalos que podés ajustar para cada vehículo.
- **Estimación según tu uso**: una notificación semanal, el día y la hora que elijas, te pregunta sólo el km actual. Con eso la app calcula cuándo vas a llegar al próximo servicio.
- **Turnos con el mecánico**: agendás un turno con todo lo que se le va a hacer, te avisa antes, y después registrás todo junto en un paso.
- **Talleres y mecánicos** guardados para no escribirlos cada vez.
- **Avisos** cuando un servicio está por vencer.
- **Exportar** el historial a CSV o PDF, y **backup / restaurar** en un archivo.
- **Español e inglés**.

## 🔒 Privacidad

Todos tus datos quedan **sólo en tu teléfono**. La app no tiene cuentas ni servidor: lo único que consulta en internet es este repositorio, para saber si salió una versión nueva.

## 👤 Autor

Hecha por **Christian Alfonzo** · Instagram [@a__chris27](https://instagram.com/a__chris27)

## 🛠️ Para desarrolladores

Es una app en **Flutter** (Dart). Si querés modificarla:

```bash
git clone https://github.com/ChrisAlf27/mis-vehiculos.git
cd mis-vehiculos
flutter pub get
flutter run            # con el teléfono conectado por USB
flutter test
flutter build apk --release
```

- **Firma**: el release se firma con la clave definida en `~/.claves-android/mis_vehiculos_key.properties`. Si ese archivo no existe, se firma con la clave de debug, así que compila igual. Ojo: un APK firmado con otra clave no se puede instalar encima del oficial (hay que desinstalar primero).
- **Textos**: todo lo que ve el usuario está en `lib/l10n/app_es.arb` y `app_en.arb`. Después de tocarlos, `flutter gen-l10n`.
- **Base de datos**: SQLite con migraciones en `lib/services/database_service.dart`. Si cambiás el esquema, subí `schemaVersion` y agregá el paso en `_onUpgrade`.
- **Actualizaciones**: la app consulta el último release de `AppInfo.githubRepo` (`lib/app_info.dart`). Si publicás tu propia versión, cambiá ese repo para que no le avise a tus usuarios de las versiones de este.
- **Publicar una versión**: subí `version:` en `pubspec.yaml` y `AppInfo.version` (tienen que coincidir), compilá y creá un release con el tag `vX.Y.Z` y el `.apk` adjunto. Las notas del release son lo que la app muestra en el aviso.

## 📄 Licencia

[MIT](LICENSE): podés usarla, modificarla y redistribuirla, manteniendo el aviso de autor.
