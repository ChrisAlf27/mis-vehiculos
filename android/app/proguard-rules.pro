# flutter_local_notifications guarda las notificaciones programadas con Gson.
# Si R8 renombra esas clases en el release, al reprogramarlas (o al reiniciar
# el teléfono) la app se cae con "Missing type parameter".
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
