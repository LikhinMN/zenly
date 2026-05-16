import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/recording/recording_service.dart';
import 'features/transcription/transcription_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ZenlyApp());
}

class ZenlyApp extends StatelessWidget {
  const ZenlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const RecordTestScreen(),
    );
  }
}

class RecordTestScreen extends StatefulWidget {
  const RecordTestScreen({super.key});

  @override
  State<RecordTestScreen> createState() => _RecordTestScreenState();
}

class _RecordTestScreenState extends State<RecordTestScreen> {
  final RecordingService _recordingService = RecordingService();
  final TranscriptionService _transcriptionService = TranscriptionService();

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _transcript;
  String? _savedPath;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recordingService.stopRecording();
      setState(() {
        _isRecording = false;
        _savedPath = path;
        _isProcessing = true;
        _transcript = null;
      });

      if (path != null) {
        final result = await _transcriptionService.transcribe(path);
        setState(() {
          _isProcessing = false;
          _transcript = result;
        });
      }
    } else {
      final path = await _recordingService.startRecording();
      if (path != null) {
        setState(() {
          _isRecording = true;
          _transcript = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _recordingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRecording
                  ? 'Recording...'
                  : _isProcessing
                  ? 'Transcribing...'
                  : 'Tap to Record',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _isProcessing ? null : _toggleRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isProcessing
                      ? Colors.grey
                      : _isRecording
                      ? Colors.red
                      : const Color(0xFF534AB7),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_transcript != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a1a1a),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _transcript!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}