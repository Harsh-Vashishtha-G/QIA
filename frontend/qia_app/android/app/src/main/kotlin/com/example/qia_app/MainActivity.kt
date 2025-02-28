package com.example.qia_app

import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.qia_app/android_services"
    private lateinit var backgroundHandler: QIABackgroundHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        backgroundHandler = QIABackgroundHandler(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    startQIAService()
                    result.success(null)
                }
                "stopForegroundService" -> {
                    stopQIAService()
                    result.success(null)
                }
                "checkPermissions" -> {
                    result.success(checkRequiredPermissions())
                }
                "requestPermissions" -> {
                    requestRequiredPermissions()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startQIAService() {
        val serviceIntent = Intent(this, QIAForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            ContextCompat.startForegroundService(this, serviceIntent)
        } else {
            startService(serviceIntent)
        }
        backgroundHandler.schedulePeriodicTasks()
    }

    private fun stopQIAService() {
        stopService(Intent(this, QIAForegroundService::class.java))
        backgroundHandler.cancelAllTasks()
    }

    private fun checkRequiredPermissions(): Boolean {
        // Implement permission checking logic
        return true
    }

    private fun requestRequiredPermissions() {
        // Implement permission request logic
    }
} 