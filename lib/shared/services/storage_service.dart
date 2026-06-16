import 'package:hive_flutter/hive_flutter.dart';
import '../models/transcript_model.dart';

class StorageService {
  static const String _boxName = 'transcripts';
  static const String _prefsBoxName = 'prefs';

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TranscriptModelAdapter());
    await Hive.openBox<TranscriptModel>(_boxName);
    await Hive.openBox(_prefsBoxName);
  }

  Box<TranscriptModel> get _box => Hive.box<TranscriptModel>(_boxName);
  Box get _prefsBox => Hive.box(_prefsBoxName);

  bool get hasOnboarded => _prefsBox.get('has_onboarded', defaultValue: false);
  Future<void> setOnboarded() async => await _prefsBox.put('has_onboarded', true);

  // Save a transcript
  Future<void> saveTranscript(TranscriptModel transcript) async {
    await _box.put(transcript.id, transcript);
  }

  // Get all transcripts sorted by newest first
  List<TranscriptModel> getAllTranscripts() {
    final transcripts = _box.values.toList();
    transcripts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return transcripts;
  }

  // Delete a transcript
  Future<void> deleteTranscript(String id) async {
    await _box.delete(id);
  }
}
