import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'voice_recognizer_interface.dart';
import '../utils/logger.dart';

class WebVoiceRecognizer implements VoiceRecognizerInterface {
  html.SpeechRecognition? _recognition;
  final _resultController = StreamController<VoiceRecognitionResult>.broadcast();
  bool _isInitialized = false;

  @override
  Stream<VoiceRecognitionResult> get resultStream => _resultController.stream;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      if (js.context.hasProperty('webkitSpeechRecognition')) {
        _recognition = html.SpeechRecognition();
      } else {
        throw UnsupportedError('Web Speech API not supported in this browser');
      }

      _setupRecognitionHandlers();
      _isInitialized = true;
    } catch (e) {
      Logger.error('Failed to initialize web voice recognition', error: e);
      rethrow;
    }
  }

  void _setupRecognitionHandlers() {
    _recognition!
      ..onResult.listen((event) {
        if (event.results.isNotEmpty) {
          final result = event.results.last;
          final transcript = result.first.transcript;
          
          _resultController.add(
            VoiceRecognitionResult(
              text: transcript,
              isFinal: result.isFinal,
              confidence: result.first.confidence,
              metadata: {
                'timeStamp': event.timeStamp,
                'resultIndex': event.resultIndex,
              },
            ),
          );
        }
      })
      ..onError.listen((event) {
        Logger.error('Web Speech API Error', error: event.error);
        _resultController.addError(event.error);
      })
      ..onEnd.listen((_) {
        // Handle recognition end
      });
  }

  @override
  Future<void> startListening(Map<String, dynamic> settings) async {
    await _initialize();

    try {
      _recognition!
        ..continuous = settings['continuous'] ?? false
        ..interimResults = settings['interimResults'] ?? true
        ..lang = settings['locale'] ?? 'en-US';

      _recognition!.start();
    } catch (e) {
      Logger.error('Failed to start web voice recognition', error: e);
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      _recognition?.stop();
    } catch (e) {
      Logger.error('Failed to stop web voice recognition', error: e);
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    _recognition?.abort();
    await _resultController.close();
  }
} 