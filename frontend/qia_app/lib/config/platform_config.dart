import '../utils/platform_utils.dart';

class PlatformConfig {
  static String get baseUrl {
    if (PlatformUtils.isWeb) {
      return 'http://localhost:8000';
    } else if (PlatformUtils.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator localhost
    } else {
      return 'http://localhost:8000';
    }
  }

  static String get wsUrl {
    final wsBase = baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/ws';
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'X-Platform': PlatformUtils.platformName,
  };

  static Duration get connectionTimeout => const Duration(seconds: 30);
  
  static Map<String, dynamic> get platformSpecificSettings {
    if (PlatformUtils.isAndroid) {
      return {
        'backgroundTaskEnabled': true,
        'batteryOptimizationEnabled': true,
        'speechRecognitionApi': 'android_native',
      };
    } else if (PlatformUtils.isIOS) {
      return {
        'backgroundTaskEnabled': true,
        'hapticFeedbackEnabled': true,
        'speechRecognitionApi': 'apple_speech',
      };
    } else {
      return {
        'backgroundTaskEnabled': false,
        'webOptimizationsEnabled': true,
      };
    }
  }
} 