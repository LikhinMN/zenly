import 'package:flutter/material.dart';
import 'features/recording/recording_service.dart';

void main() {
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
  final RecordingService _service = RecordingService();
  bool _isRecording = false;
  String? _savedPath;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _service.stopRecording();
      setState(() {
        _isRecording = false;
        _savedPath = path;
      });
    } else {
      final path = await _service.startRecording();
      if (path != null) {
        setState(() {
          _isRecording = true;
          _savedPath = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isRecording ? 'Recording...' : 'Tap to Record',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : const Color(0xFF534AB7),
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_savedPath != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Saved to:\n$_savedPath',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}