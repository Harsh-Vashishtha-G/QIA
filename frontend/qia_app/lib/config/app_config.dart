class AppConfig {
  static const String apiUrl = 'http://localhost:8000';
  static const String wsUrl = kIsWeb 
      ? 'ws://localhost:8000'  // For web
      : 'ws://10.0.2.2:8000';  // For Android emulator
  
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
  };
} 