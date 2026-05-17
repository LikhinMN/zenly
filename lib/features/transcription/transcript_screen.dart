import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart';
import '../../shared/models/transcript_model.dart';
import '../transcription/transcription_service.dart';
import 'transcript_improvement_controller.dart';
import 'widgets/transcript_widgets.dart';

class TranscriptScreen extends ConsumerStatefulWidget {
  final String? audioPath;
  final int duration;
  final String? initialTranscript;

  const TranscriptScreen({
    super.key,
    required this.audioPath,
    required this.duration,
    this.initialTranscript,
  });

  @override
  ConsumerState<TranscriptScreen> createState() => _TranscriptScreenState();
}

class _TranscriptScreenState extends ConsumerState<TranscriptScreen> {
  final TranscriptionService _service = TranscriptionService();
  String? _rawTranscript;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTranscript != null) {
      _rawTranscript = widget.initialTranscript;
      _isLoading = false;
    } else if (widget.audioPath != null) {
      _transcribe();
    } else {
      _rawTranscript = 'No audio available for transcription.';
      _isLoading = false;
    }
  }

  Future<void> _transcribe() async {
    final result = await _service.transcribe(widget.audioPath!);
    if (!mounted) return;
    setState(() {
      _rawTranscript = result;
      _isLoading = false;
    });
  }

  String get _formattedDuration {
    final m = (widget.duration ~/ 60);
    final s = widget.duration % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String get _formattedTime {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _canSave {
    final text = _rawTranscript?.trim();
    return !_isLoading &&
        !_isSaving &&
        !_hasSaved &&
        text != null &&
        text.isNotEmpty;
  }

  Future<void> _saveTranscript(String? improvedText) async {
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
    final text = _rawTranscript!.trim();
    final model = TranscriptModel(
      id: const Uuid().v4(),
      text: text,
      createdAt: DateTime.now(),
      durationSeconds: widget.duration,
      improvedText: improvedText?.trim().isNotEmpty == true
          ? improvedText!.trim()
          : null,
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

  void _copyToClipboard(String? text, String message) {
    if (text == null || text.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF534AB7),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareText(String? text, String subject) {
    if (text == null || text.trim().isEmpty) return;
    Share.share(text, subject: subject);
  }

  Future<void> _improveTranscript() async {
    final raw = _rawTranscript?.trim() ?? '';
    if (raw.isEmpty) return;
    await ref
        .read(transcriptImprovementControllerProvider.notifier)
        .improve(raw);
  }

  @override
  Widget build(BuildContext context) {
    final improvementState = ref.watch(transcriptImprovementControllerProvider);
    final improvementResult = improvementState.result;
    final isImproving = improvementState.isLoading;
    final improvementError = improvementState.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F10),
        elevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'Copy raw',
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () =>
                _copyToClipboard(_rawTranscript, 'Transcript copied'),
          ),
          IconButton(
            tooltip: 'Share raw',
            icon: const Icon(Icons.share, size: 20),
            onPressed: () => _shareText(_rawTranscript, 'Zenly Transcript'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF534AB7)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranscriptSectionHeader(
                      title: 'Transcript',
                      subtitle: '$_formattedDuration · $_formattedTime',
                    ),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: improvementResult != null
                          ? ImprovedTranscriptCard(
                              key: const ValueKey('improved'),
                              result: improvementResult,
                              onCopy: () => _copyToClipboard(
                                improvementResult.improvedTranscript,
                                'Refined transcript copied',
                              ),
                              onShare: () => _shareText(
                                improvementResult.improvedTranscript,
                                'Zenly Refined Transcript',
                              ),
                            )
                          : isImproving
                          ? const TranscriptLoadingCard(
                              key: ValueKey('loading'),
                            )
                          : EnhanceTranscriptButton(
                              key: const ValueKey('cta'),
                              onTap: _improveTranscript,
                              isLoading: isImproving,
                            ),
                    ),
                    if (improvementError != null &&
                        improvementResult == null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(
                        message: improvementError,
                        onRetry: _improveTranscript,
                      ),
                    ],
                    const SizedBox(height: 20),
                    AnimatedOpacity(
                      opacity: improvementResult != null ? 0.85 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: RawTranscriptCard(
                        transcript:
                            _rawTranscript ?? 'No transcript available.',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ActionPillButton(
                            icon: Icons.copy,
                            label: 'copy',
                            onTap: () => _copyToClipboard(
                              _rawTranscript,
                              'Transcript copied',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ActionPillButton(
                            icon: Icons.save_alt,
                            label: _isSaving ? 'saving...' : 'save',
                            isPrimary: true,
                            onTap: () => _saveTranscript(
                              improvementResult?.improvedTranscript,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ActionPillButton(
                            icon: Icons.share,
                            label: 'share',
                            onTap: () =>
                                _shareText(_rawTranscript, 'Zenly Transcript'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _NewRecordingButton(
                      onTap: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4D2A2A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFFF8A8A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: Color(0xFFFF8A8A)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
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
              style: TextStyle(fontSize: 13, color: Color(0xFF8E86E8)),
            ),
          ),
        ),
      ),
    );
  }
}
