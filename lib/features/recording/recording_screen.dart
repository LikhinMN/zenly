import 'dart:async';
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
  Timer? _timer;
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
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final path = await _service.stopRecording();
    if (path != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TranscriptScreen(
            audioPath: path,
            duration: _seconds,
          ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [14.0, 26.0, 34.0, 20.0, 30.0, 16.0, 22.0, 10.0]
                    .map((h) => Container(
                  width: 3,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F77DD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ))
                    .toList(),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF534AB7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}