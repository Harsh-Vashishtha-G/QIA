import 'package:flutter/foundation.dart';
import '../platform_utils.dart';
import 'voice_recognizer_interface.dart';
import 'android_voice_recognizer.dart';
import 'ios_voice_recognizer.dart';
import 'web_voice_recognizer.dart';
import '../utils/logger.dart';

class VoiceRecognitionService {
  late final VoiceRecognizerInterface _recognizer;
  final _recognitionController = StreamController<VoiceRecognitionResult>.broadcast();
  bool _isListening = false;

  Stream<VoiceRecognitionResult> get recognitionStream => _recognitionController.stream;
  bool get isListening => _isListening;

  VoiceRecognitionService() {
    _initializePlatformRecognizer();
  }

  void _initializePlatformRecognizer() {
    if (PlatformUtils.isAndroid) {
      _recognizer = AndroidVoiceRecognizer();
    } else if (PlatformUtils.isIOS) {
      _recognizer = IOSVoiceRecognizer();
    } else if (PlatformUtils.isWeb) {
      _recognizer = WebVoiceRecognizer();
    } else {
      throw UnsupportedError('Voice recognition not supported on this platform');
    }

    _recognizer.resultStream.listen(
      (result) => _recognitionController.add(result),
      onError: (error) => Logger.error('Voice recognition error', error: error),
    );
  }

  Future<void> startListening({
    String? locale,
    bool continuousRecognition = false,
    Map<String, dynamic>? platformSpecificSettings,
  }) async {
    if (_isListening) return;

    try {
      final settings = _getPlatformSettings(
        locale: locale,
        continuous: continuousRecognition,
        additional: platformSpecificSettings,
      );

      await _recognizer.startListening(settings);
      _isListening = true;
    } catch (e) {
      Logger.error('Failed to start voice recognition', error: e);
      rethrow;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _recognizer.stopListening();
      _isListening = false;
    } catch (e) {
      Logger.error('Failed to stop voice recognition', error: e);
      rethrow;
    }
  }

  Map<String, dynamic> _getPlatformSettings({
    String? locale,
    bool continuous = false,
    Map<String, dynamic>? additional,
  }) {
    final settings = <String, dynamic>{
      'locale': locale ?? 'en_US',
      'continuous': continuous,
    };

    if (PlatformUtils.isAndroid) {
      settings.addAll({
        'speechModel': 'free_form',
        'maxResults': 5,
        'partialResults': true,
        'enableOffline': true,
      });
    } else if (PlatformUtils.isIOS) {
      settings.addAll({
        'taskHint': 'dictation',
        'detectPauses': true,
        'powerEfficient': true,
      });
    } else if (PlatformUtils.isWeb) {
      settings.addAll({
        'interimResults': true,
        'audioContext': true,
      });
    }

    if (additional != null) {
      settings.addAll(additional);
    }

    return settings;
  }

  Future<void> dispose() async {
    await stopListening();
    await _recognitionController.close();
    await _recognizer.dispose();
  }
} 