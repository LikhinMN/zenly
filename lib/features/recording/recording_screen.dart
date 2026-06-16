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
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isStopping = false;

  Future<void> _startRecording() async {
    final hasPermission = await _service.requestPermission();
    if (!hasPermission) return;

    await _service.startRecording(skipPermissionCheck: true);
    _speechDetector.resetChunk();
    _speechDetector.start(_service);
    
    setState(() {
      _isRecording = true;
      _isProcessing = false;
      _seconds = 0;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (mounted) setState(() => _waveTick++);
    });
  }

  Future<void> _stopRecording() async {
    if (_isStopping) return;
    _isStopping = true;
    _timer?.cancel();
    _waveformTimer?.cancel();
    
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });
    
    final path = await _service.stopRecording();
    _speechDetector.stop();
    
    String finalTranscript = '';
    
    if (path != null && _speechDetector.isChunkValid) {
      final text = await _transcriptionService.transcribe(path);
      if (text != null && !text.startsWith('Error:')) {
        finalTranscript = text.trim();
      }
      try { await File(path).delete(); } catch (_) {}
    } else if (path != null) {
      try { await File(path).delete(); } catch (_) {}
    }
    
    _speechDetector.resetChunk();
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _seconds = 0;
      });
      if (finalTranscript.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TranscriptScreen(
              audioPath: null,
              duration: _seconds,
              initialTranscript: finalTranscript,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No speech detected or transcription failed.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      _isStopping = false;
    }
  }

  String get _formattedTime {
    if (_seconds == 0) return '00:00';
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformTimer?.cancel();
    _speechDetector.stop();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            
            // Central Mic Button Area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Waveform (behind/around the mic)
                        if (_isRecording)
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: List.generate(24, (i) {
                                final height = 40 + sin((_waveTick + i) * 0.5) * 60;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 4,
                                  height: height.clamp(10.0, 140.0),
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withAlpha(51),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            ),
                          ),
                        
                        if (_isProcessing)
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                              strokeWidth: 4,
                            ),
                          )
                        else
                          // Mic Button
                          GestureDetector(
                            onTap: _isRecording ? _stopRecording : _startRecording,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _isRecording ? 100 : 120,
                              height: _isRecording ? 100 : 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRecording ? theme.colorScheme.surface : theme.colorScheme.primary,
                                border: Border.all(
                                  color: theme.colorScheme.primary,
                                  width: _isRecording ? 4 : 0,
                                ),
                                boxShadow: [
                                  if (!_isRecording)
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withAlpha(77),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    )
                                ],
                              ),
                              child: Icon(
                                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                size: 48,
                                color: _isRecording ? theme.colorScheme.primary : Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    // Status Text
                    Text(
                      _isProcessing 
                        ? 'Transcribing...' 
                        : (_isRecording ? 'Listening...' : 'Tap to start speaking'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (_isRecording || _isProcessing) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
