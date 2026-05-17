import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/services/recording_service.dart';
import '../../shared/services/speech_detector_service.dart';
import '../transcription/transcript_screen.dart';
import '../transcription/transcription_service.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final RecordingService _service = RecordingService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final SpeechDetectorService _speechDetector = SpeechDetectorService(
    config: const SpeechDetectorConfig(
      sampleIntervalMs: 250,
      speechDbThreshold: -50,
      minSpeechMs: 1000,
      minConsecutiveSpeechMs: 600,
      minPeakDb: -45,
      enableLogging: true,
    ),
  );
  int _seconds = 0;
  int _waveTick = 0;
  Timer? _timer;
  Timer? _waveformTimer;
  Timer? _chunkTimer;
  bool _isRecording = false;
  bool _isRotatingChunk = false;
  bool _isStopping = false;
  String _liveTranscript = '';
  Future<void> _transcriptionQueue = Future.value();

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _service.requestPermission();
    if (!hasPermission) return;

    await _service.startRecording(skipPermissionCheck: true);
    _speechDetector.resetChunk();
    _speechDetector.start(_service);
    setState(() {
      _isRecording = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        setState(() => _waveTick++);
      }
    });
    _chunkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _rotateChunk();
    });
  }

  Future<void> _rotateChunk() async {
    if (!_isRecording || _isRotatingChunk || _isStopping) return;
    _isRotatingChunk = true;
    final path = await _service.stopRecording();
    if (path != null) {
      if (_speechDetector.isChunkValid) {
        _enqueueTranscription(path);
      } else {
        try {
          await File(path).delete();
        } catch (_) {}
        debugPrint('SpeechDetector: chunk skipped (${_speechDetector.debugStatus})');
      }
    }
    _speechDetector.resetChunk();
    if (_isRecording && !_isStopping) {
      await _service.startRecording(skipPermissionCheck: true);
    }
    _isRotatingChunk = false;
  }

  void _enqueueTranscription(String path) {
    _transcriptionQueue = _transcriptionQueue.then((_) async {
      final text = await _transcriptionService.transcribe(path);
      try {
        await File(path).delete();
      } catch (_) {}
      if (!mounted || text == null) return;
      final trimmed = text.trim();
      if (trimmed.isEmpty || trimmed.startsWith('Error:')) return;
      setState(() {
        _liveTranscript = _liveTranscript.isEmpty
            ? trimmed
            : '$_liveTranscript $trimmed';
      });
    });
  }

  Future<void> _stopRecording() async {
    _isStopping = true;
    _timer?.cancel();
    _waveformTimer?.cancel();
    _chunkTimer?.cancel();
    setState(() => _isRecording = false);
    final path = await _service.stopRecording();
    if (path != null) {
      if (_speechDetector.isChunkValid) {
        _enqueueTranscription(path);
      } else {
        try {
          await File(path).delete();
        } catch (_) {}
        debugPrint('SpeechDetector: final chunk skipped (${_speechDetector.debugStatus})');
      }
    }
    _speechDetector.stop();
    _speechDetector.resetChunk();
    await _transcriptionQueue;
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TranscriptScreen(
            audioPath: null,
            duration: _seconds,
            initialTranscript: _liveTranscript.trim(),
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
    _waveformTimer?.cancel();
    _chunkTimer?.cancel();
    _speechDetector.stop();
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
              const SizedBox(height: 20),

              // Live transcript
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: SizedBox(
                  height: 96,
                  child: SingleChildScrollView(
                    reverse: true,
                    child: Text(
                      _liveTranscript.isEmpty
                          ? 'Listening...'
                          : _liveTranscript,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFBBBBBB),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
