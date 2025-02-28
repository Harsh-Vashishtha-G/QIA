import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../services/voice_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _status = 'Ready';
  String _transcription = '';

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _voiceService.initialize();
    _voiceService.addListener(_onVoiceUpdate);
  }

  void _onVoiceUpdate() {
    setState(() {
      _transcription = _voiceService.lastWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QIA Assistant'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarGlow(
              animate: _isListening,
              glowColor: Colors.blue,
              endRadius: 75.0,
              duration: const Duration(milliseconds: 2000),
              repeatPauseDuration: const Duration(milliseconds: 100),
              repeat: true,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 80,
                color: _isListening ? Colors.green : Colors.grey,
              ).animate(target: _isListening ? 1 : 0)
                .scale(begin: 1, end: 1.2)
                .shake(duration: 500.ms),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineSmall,
            ).animate()
              .fadeIn()
              .slide(),
            const SizedBox(height: 20),
            if (_transcription.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _transcription,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ).animate()
                .fadeIn()
                .scale(),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                if (_isListening) {
                  await _voiceService.stopListening();
                } else {
                  await _voiceService.startListening();
                }
                setState(() {
                  _isListening = !_isListening;
                  _status = _isListening ? 'Listening...' : 'Ready';
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: _isListening ? Colors.red : Colors.blue,
              ),
              child: Text(
                _isListening ? 'Stop' : 'Start',
                style: const TextStyle(fontSize: 18),
              ),
            ).animate()
              .fadeIn()
              .scale(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
} 