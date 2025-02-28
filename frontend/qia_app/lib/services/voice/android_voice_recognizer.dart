import 'package:speech_recognition/speech_recognition.dart';
import 'voice_recognizer_interface.dart';

class AndroidVoiceRecognizer implements VoiceRecognizerInterface {
  final _speechRecognition = SpeechRecognition();
  final _resultController = StreamController<VoiceRecognitionResult>.broadcast();
  bool _isInitialized = false;

  @override
  Stream<VoiceRecognitionResult> get resultStream => _resultController.stream;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final available = await _speechRecognition.activate();
      if (!available) {
        throw Exception('Speech recognition not available on this device');
      }

      _speechRecognition.setRecognitionResultHandler((String text) {
        _resultController.add(VoiceRecognitionResult(
          text: text,
          isFinal: false,
        ));
      });

      _speechRecognition.setFinalRecognitionHandler((String text) {
        _resultController.add(VoiceRecognitionResult(
          text: text,
          isFinal: true,
        ));
      });

      _isInitialized = true;
    } catch (e) {
      Logger.error('Failed to initialize Android voice recognition', error: e);
      rethrow;
    }
  }

  @override
  Future<void> startListening(Map<String, dynamic> settings) async {
    await _initialize();
    
    await _speechRecognition.listen(
      locale: settings['locale'],
      partialResults: settings['partialResults'],
      onDevice: settings['enableOffline'],
    );
  }

  @override
  Future<void> stopListening() async {
    await _speechRecognition.stop();
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _resultController.close();
    await _speechRecognition.cancel();
  }
} 