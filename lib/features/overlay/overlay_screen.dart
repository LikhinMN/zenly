import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../../shared/services/recording_service.dart';
import '../../shared/services/transcript_cleanup_service.dart';
import '../transcription/transcription_service.dart';

enum OverlayState { idle, recording, result }

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  final RecordingService _recordingService = RecordingService();
  final TranscriptionService _transcriptionService = TranscriptionService();
  final TranscriptCleanupService _cleanupService = TranscriptCleanupService();
  OverlayState _state = OverlayState.idle;
  Timer? _timer;
  Timer? _waveTimer;
  Timer? _copiedTimer;
  int _seconds = 0;
  int _waveTick = 0;
  bool _isProcessing = false;
  bool _isImproving = false;
  bool _copied = false;
  String _transcript = '';
  String? _improved;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _waveTimer?.cancel();
    _copiedTimer?.cancel();
    _recordingService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recordingService.requestPermission();
    if (!hasPermission) return;

    final started = await _recordingService.startRecording(
      skipPermissionCheck: true,
    );
    if (started == null) return;

    _timer?.cancel();
    _waveTimer?.cancel();
    setState(() {
      _state = OverlayState.recording;
      _seconds = 0;
      _waveTick = 0;
      _isProcessing = false;
      _isImproving = false;
      _copied = false;
      _transcript = '';
      _improved = null;
      _errorMessage = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (mounted) setState(() => _waveTick++);
    });
  }

  Future<void> _stopRecording() async {
    if (_state != OverlayState.recording) return;

    _timer?.cancel();
    _waveTimer?.cancel();
    setState(() {
      _state = OverlayState.result;
      _isProcessing = true;
      _isImproving = false;
      _copied = false;
      _transcript = '';
      _improved = null;
      _errorMessage = null;
    });

    final path = await _recordingService.stopRecording();
    String? text;
    if (path != null) {
      try {
        text = await _transcriptionService.transcribe(path);
      } finally {
        try {
          await File(path).delete();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _transcript = text?.trim() ?? '';
    });
  }

  Future<void> _improveTranscript() async {
    final raw = _transcript.trim();
    if (raw.isEmpty || _isImproving) return;

    setState(() {
      _isImproving = true;
      _errorMessage = null;
    });

    try {
      final result = await _cleanupService.improveTranscript(raw);
      if (!mounted) return;
      setState(() => _improved = result.improvedTranscript.trim());
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isImproving = false);
    }
  }

  void _copyTranscript() {
    final text = (_improved?.trim().isNotEmpty == true)
        ? _improved!.trim()
        : _transcript.trim();
    if (text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text));
    _copiedTimer?.cancel();
    setState(() => _copied = true);
    _copiedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _resetToIdle() {
    _timer?.cancel();
    _waveTimer?.cancel();
    setState(() {
      _state = OverlayState.idle;
      _seconds = 0;
      _waveTick = 0;
      _isProcessing = false;
      _isImproving = false;
      _copied = false;
      _transcript = '';
      _improved = null;
      _errorMessage = null;
    });
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1F1F1F)),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAA000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case OverlayState.idle:
        return _buildIdle();
      case OverlayState.recording:
        return _buildRecording();
      case OverlayState.result:
        return _buildResult();
    }
  }

  Widget _buildIdle() {
    return Column(
      key: const ValueKey('idle'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Zenly',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7F77DD),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF534AB7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.mic, size: 18),
                label: const Text('Record'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: FlutterOverlayWindow.closeOverlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: const Color(0xFFB0B0B0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                ),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Close'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecording() {
    return Column(
      key: const ValueKey('recording'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formattedTime,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7F77DD),
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(12, (i) {
                final animatedHeight = 12 + sin((_waveTick + i) * 0.6) * 14;
                final height = animatedHeight.clamp(6.0, 36.0);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F77DD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1D1520),
              border: Border.all(color: const Color(0xFF534AB7), width: 2),
            ),
            child: Center(
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF534AB7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'recording · tap to stop',
          style: TextStyle(fontSize: 11, color: Color(0xFF7F77DD)),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final displayText = _improved?.trim().isNotEmpty == true
        ? _improved!.trim()
        : _transcript.trim();
    final hasText = displayText.isNotEmpty;

    return Column(
      key: const ValueKey('result'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Transcript',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E86E8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: _isProcessing
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF534AB7),
                    strokeWidth: 2,
                  ),
                )
              : SingleChildScrollView(
                  child: Text(
                    hasText ? displayText : 'No transcript yet.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFCCCCCC),
                      height: 1.4,
                    ),
                  ),
                ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFFF8A8A)),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _isProcessing || !hasText ? null : _improveTranscript,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF534AB7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_isImproving ? 'Improving...' : 'Improve'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing || !hasText ? null : _copyTranscript,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: const Color(0xFFE0E0E0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                ),
                child: const Text('Copy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_copied)
          const Center(
            child: Text(
              'Copied!',
              style: TextStyle(fontSize: 11, color: Color(0xFF7F77DD)),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _resetToIdle,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF141414),
            foregroundColor: const Color(0xFF8E86E8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
          ),
          child: const Text('New'),
        ),
      ],
    );
  }
}

