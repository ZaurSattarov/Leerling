package com.klantio.leerling

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationsChannelName = "com.klantio.leerling/notifications"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("KlantioChannels", "MainActivity.onCreate start")
        NotificationChannels.ensureCreated(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, notificationsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ensureNotificationChannels" -> {
                        NotificationChannels.ensureCreated(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
