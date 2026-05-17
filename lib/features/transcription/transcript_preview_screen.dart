import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/models/transcript_improvement_result.dart';
import '../../shared/models/transcript_model.dart';
import '../recording/recording_screen.dart';
import 'widgets/transcript_widgets.dart';

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
    final text = transcript.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to share'),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Share.share(text, subject: 'Transcript');
  }

  void _copyImproved(BuildContext context) {
    final text = transcript.improvedText?.trim();
    if (text == null || text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refined transcript copied'),
        backgroundColor: Color(0xFF534AB7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareImproved(BuildContext context) {
    final text = transcript.improvedText?.trim();
    if (text == null || text.isEmpty) return;
    Share.share(text, subject: 'Zenly Refined Transcript');
  }

  @override
  Widget build(BuildContext context) {
    final hasImproved = transcript.improvedText?.trim().isNotEmpty == true;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F10),
        elevation: 0,
        title: const SizedBox.shrink(),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TranscriptSectionHeader(
                title: 'Transcript',
                subtitle:
                    '${_formatDuration(transcript.durationSeconds)} · ${_formatTime(transcript.createdAt)}',
              ),
              const SizedBox(height: 20),
              if (hasImproved) ...[
                ImprovedTranscriptCard(
                  result: TranscriptImprovementResult(
                    improvedTranscript: transcript.improvedText!.trim(),
                    changesMade: const [],
                    confidence: TranscriptConfidence.medium,
                  ),
                  onCopy: () => _copyImproved(context),
                  onShare: () => _shareImproved(context),
                ),
                const SizedBox(height: 20),
              ],
              RawTranscriptCard(transcript: transcript.text),
              const SizedBox(height: 20),
              _NewRecordingButton(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecordingScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewRecordingButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewRecordingButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: const Center(
            child: Text(
              '+ new recording',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8E86E8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
