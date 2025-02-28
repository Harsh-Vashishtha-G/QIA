import 'package:flutter/services.dart';
import '../utils/logger.dart';

class AndroidServiceHandler {
  static const platform = MethodChannel('com.example.qia_app/android_services');
  
  Future<void> startForegroundService() async {
    try {
      await platform.invokeMethod('startForegroundService');
    } on PlatformException catch (e) {
      Logger.error('Failed to start foreground service', error: e);
    }
  }
  
  Future<void> stopForegroundService() async {
    try {
      await platform.invokeMethod('stopForegroundService');
    } on PlatformException catch (e) {
      Logger.error('Failed to stop foreground service', error: e);
    }
  }
  
  Future<bool> checkPermissions() async {
    try {
      final permissions = await platform.invokeMethod('checkPermissions');
      return permissions ?? false;
    } on PlatformException catch (e) {
      Logger.error('Failed to check permissions', error: e);
      return false;
    }
  }
  
  Future<void> requestPermissions() async {
    try {
      await platform.invokeMethod('requestPermissions');
    } on PlatformException catch (e) {
      Logger.error('Failed to request permissions', error: e);
    }
  }
} 