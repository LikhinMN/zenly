import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/models/transcript_model.dart';
import '../recording/recording_screen.dart';

class TranscriptPreviewScreen extends StatelessWidget {
  final TranscriptModel transcript;

  const TranscriptPreviewScreen({
    super.key,
    required this.transcript,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return 'Today, $h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  void _copyTranscript(BuildContext context) {
    Clipboard.setData(ClipboardData(text: transcript.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Color(0xFF534AB7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareTranscript(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing is not available yet'),
        backgroundColor: Color(0xFF1A1A1A),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text('Transcript'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () => _copyTranscript(context),
            tooltip: 'Copy',
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => _shareTranscript(context),
            tooltip: 'Share',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatTime(transcript.createdAt)} · ${_formatDuration(transcript.durationSeconds)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      transcript.text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFBBBBBB),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecordingScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: const Center(
                    child: Text(
                      '+ new recording',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF534AB7),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
