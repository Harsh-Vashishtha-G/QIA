package com.example.qia_app

import android.content.Context
import android.os.PowerManager
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import androidx.work.WorkInfo
import androidx.work.WorkManager
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class QIAPowerManager(private val context: Context) {
    private val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
    private val workManager = WorkManager.getInstance(context)
    
    private val _batteryState = MutableStateFlow<BatteryState>(BatteryState.UNKNOWN)
    val batteryState: StateFlow<BatteryState> = _batteryState

    private var wakeLock: PowerManager.WakeLock? = null
    
    init {
        monitorBatteryState()
    }

    fun optimizeForBatteryState() {
        when (batteryState.value) {
            BatteryState.CRITICAL -> enterCriticalMode()
            BatteryState.LOW -> enterLowPowerMode()
            BatteryState.NORMAL -> enterNormalMode()
            BatteryState.CHARGING -> enterChargingMode()
            else -> enterNormalMode()
        }
    }

    private fun monitorBatteryState() {
        val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { filter ->
            context.registerReceiver(null, filter)
        }

        batteryStatus?.let { intent ->
            val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            val batteryPct = level * 100 / scale.toFloat()
            
            val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                    status == BatteryManager.BATTERY_STATUS_FULL

            _batteryState.value = when {
                isCharging -> BatteryState.CHARGING
                batteryPct <= 15 -> BatteryState.CRITICAL
                batteryPct <= 30 -> BatteryState.LOW
                else -> BatteryState.NORMAL
            }
        }
    }

    private fun enterCriticalMode() {
        // Cancel all non-essential background work
        workManager.cancelAllWorkByTag("non_essential")
        
        // Reduce AI processing frequency
        QIAWorkerConfigs.apply {
            processingInterval = 30L // minutes
            batchSize = 5
            enableOfflineProcessing = true
        }
        
        // Release wake lock if held
        releaseWakeLock()
    }

    private fun enterLowPowerMode() {
        // Reduce background work frequency
        workManager.cancelAllWorkByTag("optional")
        
        QIAWorkerConfigs.apply {
            processingInterval = 15L // minutes
            batchSize = 10
            enableOfflineProcessing = true
        }
    }

    private fun enterNormalMode() {
        QIAWorkerConfigs.apply {
            processingInterval = 5L // minutes
            batchSize = 20
            enableOfflineProcessing = false
        }
        
        // Resume normal background work
        scheduleNormalWorkload()
    }

    private fun enterChargingMode() {
        // Process pending tasks and sync data
        QIAWorkerConfigs.apply {
            processingInterval = 1L // minute
            batchSize = 50
            enableOfflineProcessing = false
        }
        
        // Schedule data sync and maintenance tasks
        scheduleMaintenanceTasks()
    }

    fun acquireWakeLock(timeout: Long) {
        releaseWakeLock()
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "QIA::ProcessingWakeLock"
        ).apply {
            acquire(timeout)
        }
    }

    fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    private fun scheduleNormalWorkload() {
        // Implement normal workload scheduling
    }

    private fun scheduleMaintenanceTasks() {
        // Schedule maintenance during charging
    }

    fun isIgnoringBatteryOptimizations(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            true
        }
    }

    companion object {
        enum class BatteryState {
            UNKNOWN, CRITICAL, LOW, NORMAL, CHARGING
        }
    }
} 