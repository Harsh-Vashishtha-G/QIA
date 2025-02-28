import 'dart:async';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_recognizer_interface.dart';
import '../utils/logger.dart';

class IOSVoiceRecognizer implements VoiceRecognizerInterface {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _resultController = StreamController<VoiceRecognitionResult>.broadcast();
  bool _isInitialized = false;
  
  @override
  Stream<VoiceRecognitionResult> get resultStream => _resultController.stream;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final available = await _speech.initialize(
        onError: _handleError,
        options: [
          stt.SpeechToTextOptions.requestPermission,
          stt.SpeechToTextOptions.enableOnDeviceSpeechRecognition,
        ],
      );

      if (!available) {
        throw PlatformException(
          code: 'speech_recognition_error',
          message: 'Speech recognition not available on this device',
        );
      }

      _isInitialized = true;
    } catch (e) {
      Logger.error('Failed to initialize iOS voice recognition', error: e);
      rethrow;
    }
  }

  @override
  Future<void> startListening(Map<String, dynamic> settings) async {
    await _initialize();

    try {
      await _speech.listen(
        onResult: _handleSpeechResult,
        localeId: settings['locale'],
        listenMode: settings['continuous'] 
            ? stt.ListenMode.dictation
            : stt.ListenMode.confirmation,
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
        onSoundLevelChange: _handleSoundLevel,
      );
    } catch (e) {
      Logger.error('Failed to start iOS voice recognition', error: e);
      rethrow;
    }
  }

  void _handleSpeechResult(stt.SpeechRecognitionResult result) {
    try {
      _resultController.add(
        VoiceRecognitionResult(
          text: result.recognizedWords,
          isFinal: result.finalResult,
          confidence: result.confidence,
          metadata: {
            'hasConfidenceRating': result.hasConfidenceRating,
            'alternates': result.alternates.map((alt) => alt.recognizedWords).toList(),
          },
        ),
      );
    } catch (e) {
      Logger.error('Error processing speech result', error: e);
    }
  }

  void _handleError(String error) {
    Logger.error('iOS Speech Recognition Error', error: error);
    _resultController.addError(error);
  }

  void _handleSoundLevel(double level) {
    // Optionally handle sound level changes for UI feedback
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      Logger.error('Failed to stop iOS voice recognition', error: e);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _resultController.close();
  }
} 