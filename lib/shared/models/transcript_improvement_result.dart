enum TranscriptConfidence { low, medium, high }

class TranscriptImprovementResult {
  final String improvedTranscript;
  final List<String> changesMade;
  final TranscriptConfidence confidence;

  const TranscriptImprovementResult({
    required this.improvedTranscript,
    required this.changesMade,
    required this.confidence,
  });

  factory TranscriptImprovementResult.fromJson(Map<String, dynamic> json) {
    final improved = json['improved_transcript']?.toString().trim() ?? '';
    final changes = json['changes_made'] is List
        ? (json['changes_made'] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];
    final confidenceRaw = json['confidence']?.toString().toLowerCase() ?? 'low';
    final confidence = TranscriptConfidence.values.firstWhere(
      (value) => value.name == confidenceRaw,
      orElse: () => TranscriptConfidence.low,
    );

    return TranscriptImprovementResult(
      improvedTranscript: improved,
      changesMade: changes,
      confidence: confidence,
    );
  }
}
