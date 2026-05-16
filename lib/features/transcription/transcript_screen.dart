import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../transcription/transcription_service.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart';
import '../../shared/models/transcript_model.dart';

class TranscriptScreen extends StatefulWidget {
  final String audioPath;
  final int duration;

  const TranscriptScreen({
    super.key,
    required this.audioPath,
    required this.duration,
  });

  @override
  State<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends State<TranscriptScreen> {
  final TranscriptionService _service = TranscriptionService();
  String? _transcript;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    _transcribe();
  }

  Future<void> _transcribe() async {
    final result = await _service.transcribe(widget.audioPath);
    setState(() {
      _transcript = result;
      _isLoading = false;
    });
  }

  String get _formattedDuration {
    final m = (widget.duration ~/ 60);
    final s = widget.duration % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  bool get _canSave {
    final text = _transcript?.trim();
    return !_isLoading && !_isSaving && !_hasSaved && text != null && text.isNotEmpty;
  }

  Future<void> _saveTranscript() async {
    if (!_canSave) {
      if (_hasSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transcript already saved'),
            backgroundColor: Color(0xFF534AB7),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    final text = _transcript!.trim();
    final model = TranscriptModel(
      id: const Uuid().v4(),
      text: text,
      createdAt: DateTime.now(),
      durationSeconds: widget.duration,
    );
    await storageService.saveTranscript(model);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _hasSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transcript saved'),
        backgroundColor: Color(0xFF534AB7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyToClipboard() {
    if (_transcript != null) {
      Clipboard.setData(ClipboardData(text: _transcript!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard'),
          backgroundColor: Color(0xFF534AB7),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Transcript',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE0E0E0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formattedDuration} · just now',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 16),

              // Transcript box
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF534AB7),
                    ),
                  )
                      : SingleChildScrollView(
                    child: Text(
                      _transcript ?? 'No transcript available.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFBBBBBB),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy,
                      label: 'copy',
                      onTap: _copyToClipboard,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.save_alt,
                      label: 'save',
                      isPrimary: true,
                      onTap: _saveTranscript,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share,
                      label: 'share',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // New recording button
              GestureDetector(
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF534AB7)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF534AB7)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18,
                color: isPrimary ? Colors.white : const Color(0xFF888888)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isPrimary ? Colors.white : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }
}