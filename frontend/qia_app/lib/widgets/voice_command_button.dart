import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:async';

class VoiceCommandButton extends StatefulWidget {
  final bool isListening;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;

  const VoiceCommandButton({
    Key? key,
    required this.isListening,
    required this.onStartListening,
    required this.onStopListening,
  }) : super(key: key);

  @override
  _VoiceCommandButtonState createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _audioRecorder = Record();
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startRecording(),
      onTapUp: (_) => _stopRecording(),
      onTapCancel: () => _stopRecording(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.isListening ? 80 : 70,
        height: widget.isListening ? 80 : 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isListening ? Colors.red : Colors.blue,
          boxShadow: [
            BoxShadow(
              color: (widget.isListening ? Colors.red : Colors.blue)
                  .withOpacity(0.5),
              blurRadius: widget.isListening ? 20 : 10,
              spreadRadius: widget.isListening ? 10 : 5,
            ),
          ],
        ),
        child: Icon(
          widget.isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: widget.isListening ? 40 : 35,
        ),
      ),
    );
  }

  void _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start();
      widget.onStartListening();
      _startPulseAnimation();
    }
  }

  void _stopRecording() async {
    final path = await _audioRecorder.stop();
    widget.onStopListening();
    _stopPulseAnimation();
    if (path != null) {
      // Send audio file to backend
    }
  }

  void _startPulseAnimation() {
    _animationController.repeat(reverse: true);
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      _animationController.forward(from: 0.0);
    });
  }

  void _stopPulseAnimation() {
    _animationController.stop();
    _pulseTimer?.cancel();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
} 