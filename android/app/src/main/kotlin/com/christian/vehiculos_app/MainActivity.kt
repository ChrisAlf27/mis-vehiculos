package com.christian.vehiculos_app

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Los backups van siempre a Descargas/MisVehiculos: es una carpeta pública,
 * así que sobrevive a desinstalar la app y se ve desde el administrador de
 * archivos.
 */
class MainActivity : FlutterActivity() {
    private companion object {
        const val CHANNEL = "mis_vehiculos/backups"
        const val FOLDER = "MisVehiculos"
        const val PICK_REQUEST = 4711
    }

    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "save" -> save(
                            call.argument<String>("name")!!,
                            call.argument<ByteArray>("bytes")!!,
                            result,
                        )
                        "list" -> list(result)
                        "read" -> result.success(read(Uri.parse(call.argument<String>("uri")!!)))
                        "pick" -> pick(result)
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("io", e.message, null)
                }
            }
    }

    // Antes de Android 10 se escribe el archivo directo y hace falta permiso.
    private fun legacyDir(): File =
        File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), FOLDER)

    private fun lacksLegacyPermission(permission: String) =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED

    private fun save(name: String, bytes: ByteArray, result: MethodChannel.Result) {
        if (lacksLegacyPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)) {
            result.error("permission", null, null)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, name)
                put(MediaStore.Downloads.MIME_TYPE, "application/json")
                put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$FOLDER")
            }
            val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("insert")
            contentResolver.openOutputStream(uri)!!.use { it.write(bytes) }
        } else {
            val dir = legacyDir().apply { mkdirs() }
            val file = File(dir, name)
            file.writeBytes(bytes)
            MediaScannerConnection.scanFile(this, arrayOf(file.path), null, null)
        }
        result.success(null)
    }

    /** Los backups de la carpeta, del más nuevo al más viejo. */
    private fun list(result: MethodChannel.Result) {
        if (lacksLegacyPermission(Manifest.permission.READ_EXTERNAL_STORAGE)) {
            result.error("permission", null, null)
            return
        }
        val files = mutableListOf<Map<String, Any>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Sin permisos, MediaStore devuelve los archivos que creó esta
            // instalación de la app. Los demás se buscan con "pick".
            val projection = arrayOf(
                MediaStore.Downloads._ID,
                MediaStore.Downloads.DISPLAY_NAME,
                MediaStore.Downloads.DATE_MODIFIED,
            )
            contentResolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                projection,
                "${MediaStore.Downloads.RELATIVE_PATH} = ?",
                arrayOf("${Environment.DIRECTORY_DOWNLOADS}/$FOLDER/"),
                "${MediaStore.Downloads.DATE_MODIFIED} DESC",
            )?.use { c ->
                while (c.moveToNext()) {
                    val uri = Uri.withAppendedPath(
                        MediaStore.Downloads.EXTERNAL_CONTENT_URI, c.getLong(0).toString())
                    files.add(mapOf(
                        "uri" to uri.toString(),
                        "name" to c.getString(1),
                        "modified" to c.getLong(2) * 1000,
                    ))
                }
            }
        } else {
            legacyDir().listFiles()
                ?.filter { it.isFile }
                ?.sortedByDescending { it.lastModified() }
                ?.forEach {
                    files.add(mapOf(
                        "uri" to Uri.fromFile(it).toString(),
                        "name" to it.name,
                        "modified" to it.lastModified(),
                    ))
                }
        }
        result.success(files)
    }

    private fun read(uri: Uri): ByteArray =
        contentResolver.openInputStream(uri)!!.use { it.readBytes() }

    /** Selector de archivos del sistema, abierto en la carpeta de backups. */
    private fun pick(result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                putExtra(
                    DocumentsContract.EXTRA_INITIAL_URI,
                    DocumentsContract.buildDocumentUri(
                        "com.android.externalstorage.documents",
                        "primary:${Environment.DIRECTORY_DOWNLOADS}/$FOLDER",
                    ),
                )
            }
        }
        startActivityForResult(intent, PICK_REQUEST)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_REQUEST) return
        val result = pendingPick ?: return
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            result.success(read(uri))
        } catch (e: Exception) {
            result.error("io", e.message, null)
        }
    }
}
