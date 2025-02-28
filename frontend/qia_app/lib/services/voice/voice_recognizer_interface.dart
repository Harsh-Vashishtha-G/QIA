abstract class VoiceRecognizerInterface {
  Stream<VoiceRecognitionResult> get resultStream;
  
  Future<void> startListening(Map<String, dynamic> settings);
  Future<void> stopListening();
  Future<void> dispose();
}

class VoiceRecognitionResult {
  final String text;
  final bool isFinal;
  final double? confidence;
  final Map<String, dynamic>? metadata;

  VoiceRecognitionResult({
    required this.text,
    this.isFinal = false,
    this.confidence,
    this.metadata,
  });
} 