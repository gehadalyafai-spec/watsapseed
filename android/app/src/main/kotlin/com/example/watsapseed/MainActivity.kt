package com.example.watsapseed

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
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
