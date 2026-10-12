package com.example.watsapseed

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "watsapseed/whatsapp"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
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
