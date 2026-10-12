package com.example.watsapseed

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "watsapseed/whatsapp"
    private var methodChannel: MethodChannel? = null
    private var pendingSharedText: String? = null

    private fun extractSharedText(sourceIntent: Intent?): String? {
        if (sourceIntent == null) return null

        val text = when (sourceIntent.action) {
            Intent.ACTION_SEND -> {
                if (sourceIntent.type != "text/plain") return null
                sourceIntent.getStringExtra(Intent.EXTRA_TEXT)
            }
            Intent.ACTION_PROCESS_TEXT -> {
                sourceIntent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            }
            else -> null
        }

        return text
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val sharedText = extractSharedText(intent)
        if (sharedText != null) {
            pendingSharedText = sharedText
            methodChannel?.invokeMethod("incomingSharedText", sharedText)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        pendingSharedText = pendingSharedText ?: extractSharedText(intent)

        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "consumeSharedText") {
                val sharedText = pendingSharedText
                pendingSharedText = null
                result.success(sharedText)
                return@setMethodCallHandler
            }
            if (call.method == "saveImage") {
                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName")
                    ?.takeIf { it.isNotBlank() }
                    ?: "raqm-mubasher-qr.png"

                if (bytes == null || bytes.isEmpty()) {
                    result.error("INVALID_ARGUMENTS", "Missing image bytes", null)
                    return@setMethodCallHandler
                }

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val values = ContentValues().apply {
                            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                            put(
                                MediaStore.Images.Media.RELATIVE_PATH,
                                Environment.DIRECTORY_PICTURES + "/RaqmMubasher"
                            )
                            put(MediaStore.Images.Media.IS_PENDING, 1)
                        }

                        val uri = contentResolver.insert(
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                            values
                        ) ?: throw IllegalStateException("Unable to create image")

                        contentResolver.openOutputStream(uri)?.use { stream ->
                            stream.write(bytes)
                        } ?: throw IllegalStateException("Unable to write image")

                        values.clear()
                        values.put(MediaStore.Images.Media.IS_PENDING, 0)
                        contentResolver.update(uri, values, null, null)
                        result.success(uri.toString())
                    } else {
                        val baseDir = getExternalFilesDir(Environment.DIRECTORY_PICTURES)
                            ?: filesDir
                        val imageDir = File(baseDir, "RaqmMubasher").apply { mkdirs() }
                        val imageFile = File(imageDir, fileName)
                        imageFile.writeBytes(bytes)
                        result.success(imageFile.absolutePath)
                    }
                } catch (e: Exception) {
                    result.error("SAVE_IMAGE_FAILED", e.message, null)
                }
                return@setMethodCallHandler
            }

            if (call.method == "shareImage") {
                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName")
                    ?.takeIf { it.isNotBlank() }
                    ?: "direct-number-qr.png"
                val text = call.argument<String>("text").orEmpty()

                if (bytes == null || bytes.isEmpty()) {
                    result.error("INVALID_ARGUMENTS", "Missing image bytes", null)
                    return@setMethodCallHandler
                }

                try {
                    val shareDir = File(cacheDir, "shared").apply { mkdirs() }
                    val imageFile = File(shareDir, fileName)
                    imageFile.writeBytes(bytes)

                    val imageUri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.fileprovider",
                        imageFile
                    )

                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "image/png"
                        putExtra(Intent.EXTRA_STREAM, imageUri)
                        if (text.isNotBlank()) {
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }

                    startActivity(Intent.createChooser(shareIntent, null))
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SHARE_IMAGE_FAILED", e.message, null)
                }
                return@setMethodCallHandler
            }

            if (call.method == "shareText") {
                val text = call.argument<String>("text").orEmpty()
                if (text.isBlank()) {
                    result.error("INVALID_ARGUMENTS", "Missing text", null)
                    return@setMethodCallHandler
                }

                try {
                    val shareIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    startActivity(Intent.createChooser(shareIntent, null))
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SHARE_FAILED", e.message, null)
                }
                return@setMethodCallHandler
            }

            if (call.method != "openWhatsApp") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val phone = call.argument<String>("phone").orEmpty()
            val message = call.argument<String>("message").orEmpty()
            val packageName = call.argument<String>("packageName").orEmpty()

            if (phone.isBlank() || packageName.isBlank()) {
                result.error("INVALID_ARGUMENTS", "Missing phone or package name", null)
                return@setMethodCallHandler
            }

            try {
                val uriBuilder = Uri.Builder()
                    .scheme("https")
                    .authority("wa.me")
                    .appendPath(phone)

                if (message.isNotBlank()) {
                    uriBuilder.appendQueryParameter("text", message)
                }

                val intent = Intent(Intent.ACTION_VIEW, uriBuilder.build()).apply {
                    setPackage(packageName)
                }

                startActivity(intent)
                result.success(true)
            } catch (_: ActivityNotFoundException) {
                result.success(false)
            } catch (e: Exception) {
                result.error("OPEN_FAILED", e.message, null)
            }
        }
    }
}
