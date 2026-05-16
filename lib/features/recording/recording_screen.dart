import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/services/recording_service.dart';
import '../transcription/transcript_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final RecordingService _service = RecordingService();
  int _seconds = 0;
  int _waveTick = 0;
  Timer? _timer;
  Timer? _waveformTimer;
  bool _isRecording = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final path = await _service.startRecording();
    if (path != null) {
      setState(() {
        _isRecording = true;
        _filePath = path;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
      });
      _waveformTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) {
          setState(() => _waveTick++);
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _waveformTimer?.cancel();
    setState(() => _isRecording = false);
    final path = await _service.stopRecording();
    if (path != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TranscriptScreen(audioPath: path, duration: _seconds),
        ),
      );
    }
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer
              Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF534AB7),
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 20),

              // Animated waveform
              SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(12, (i) {
                      final baseHeight = 8.0 + (i % 3) * 6.0;
                      final animatedHeight =
                          14 + sin((_waveTick + i) * 0.6) * 16;
                      final height = _isRecording ? animatedHeight : baseHeight;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 3,
                        height: height.clamp(6.0, 40.0),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? const Color(0xFF7F77DD)
                              : const Color(0xFF3C3489),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Stop button
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1D1520),
                    border: Border.all(
                      color: const Color(0xFF534AB7),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF534AB7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'recording · tap to stop',
                style: TextStyle(fontSize: 12, color: Color(0xFF534AB7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
