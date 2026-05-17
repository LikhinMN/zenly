import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/transcript_improvement_result.dart';
import '../../shared/services/transcript_cleanup_service.dart';

class TranscriptImprovementState {
  final bool isLoading;
  final TranscriptImprovementResult? result;
  final String? errorMessage;

  const TranscriptImprovementState({
    required this.isLoading,
    required this.result,
    required this.errorMessage,
  });

  const TranscriptImprovementState.idle()
      : isLoading = false,
        result = null,
        errorMessage = null;

  TranscriptImprovementState copyWith({
    bool? isLoading,
    TranscriptImprovementResult? result,
    String? errorMessage,
  }) {
    return TranscriptImprovementState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }
}

class TranscriptImprovementController
    extends StateNotifier<TranscriptImprovementState> {
  final TranscriptCleanupService _service;

  TranscriptImprovementController({TranscriptCleanupService? service})
      : _service = service ?? TranscriptCleanupService(),
        super(const TranscriptImprovementState.idle());

  Future<void> improve(String rawText) async {
    if (state.isLoading) return;
    if (state.result != null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.improveTranscript(rawText);
      state = TranscriptImprovementState(
        isLoading: false,
        result: result,
        errorMessage: null,
      );
    } catch (error) {
      state = TranscriptImprovementState(
        isLoading: false,
        result: state.result,
        errorMessage: error.toString(),
      );
    }
  }

  void reset() {
    state = const TranscriptImprovementState.idle();
  }
}

final transcriptImprovementControllerProvider = StateNotifierProvider<
    TranscriptImprovementController, TranscriptImprovementState>(
  (ref) => TranscriptImprovementController(),
);

