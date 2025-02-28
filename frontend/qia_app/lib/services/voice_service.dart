import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/material.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speechToText.initialize(
      onError: (error) => print('Error: $error'),
      onStatus: (status) => print('Status: $status'),
    );
    
    return _isInitialized;
  }

  Future<void> startListening() async {
    if (!_isInitialized) await initialize();
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_US',
    );
    
    _isListening = true;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;
    notifyListeners();
  }
} 