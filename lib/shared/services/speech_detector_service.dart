import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'recording_service.dart';

class SpeechDetectorConfig {
  final int sampleIntervalMs;
  final double speechDbThreshold;
  final int minSpeechMs;
  final int minConsecutiveSpeechMs;
  final double minPeakDb;
  final bool enableLogging;
  final int logEverySamples;

  const SpeechDetectorConfig({
    this.sampleIntervalMs = 250,
    this.speechDbThreshold = -50,
    this.minSpeechMs = 1000,
    this.minConsecutiveSpeechMs = 600,
    this.minPeakDb = -45,
    this.enableLogging = true,
    this.logEverySamples = 8,
  });
}

class SpeechDetectorService {
  final SpeechDetectorConfig config;
  StreamSubscription<Amplitude>? _subscription;
  int _totalSpeechMs = 0;
  int _consecutiveSpeechMs = 0;
  double _peakDb = -120;
  int _samples = 0;
  bool _hasSpeechSegment = false;

  SpeechDetectorService({this.config = const SpeechDetectorConfig()});

  void start(RecordingService recordingService) {
    _subscription?.cancel();
    _subscription = recordingService
        .onAmplitudeChanged(Duration(milliseconds: config.sampleIntervalMs))
        .listen(_onSample, onError: (e) {
      if (config.enableLogging) {
        debugPrint('SpeechDetector: amplitude stream error: $e');
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void resetChunk() {
    _totalSpeechMs = 0;
    _consecutiveSpeechMs = 0;
    _peakDb = -120;
    _samples = 0;
    _hasSpeechSegment = false;
  }

  bool get isChunkValid {
    return _hasSpeechSegment &&
        _totalSpeechMs >= config.minSpeechMs &&
        _peakDb >= config.minPeakDb;
  }

  String get debugStatus {
    return 'speechMs=$_totalSpeechMs, peakDb=${_peakDb.toStringAsFixed(1)}, '
        'hasSegment=$_hasSpeechSegment';
  }

  void _onSample(Amplitude amplitude) {
    _samples++;
    final currentDb = amplitude.current;
    if (currentDb > _peakDb) _peakDb = currentDb;

    if (currentDb >= config.speechDbThreshold) {
      _consecutiveSpeechMs += config.sampleIntervalMs;
      _totalSpeechMs += config.sampleIntervalMs;
      if (_consecutiveSpeechMs >= config.minConsecutiveSpeechMs) {
        _hasSpeechSegment = true;
      }
    } else {
      _consecutiveSpeechMs = 0;
    }

    if (config.enableLogging && _samples % config.logEverySamples == 0) {
      debugPrint('SpeechDetector: db=${currentDb.toStringAsFixed(1)} '
          'peak=${_peakDb.toStringAsFixed(1)} '
          'speechMs=$_totalSpeechMs '
          'segment=$_hasSpeechSegment');
    }
  }
}

