package com.example.qia_app

object QIAWorkerConfigs {
    var processingInterval: Long = 5L // Default 5 minutes
    var batchSize: Int = 20 // Default batch size
    var enableOfflineProcessing: Boolean = false
    
    // AI processing configs
    var maxConcurrentTasks: Int = 3
    var taskTimeout: Long = 30000L // 30 seconds
    var retryCount: Int = 3
} 