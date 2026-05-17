import 'package:flutter/material.dart';
import '../../../shared/models/transcript_improvement_result.dart';

class TranscriptSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const TranscriptSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFFE7E7E7),
            letterSpacing: 0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ],
    );
  }
}

class TranscriptCard extends StatelessWidget {
  final String label;
  final String transcript;
  final Color backgroundColor;
  final Color borderColor;
  final bool isPrimary;

  const TranscriptCard({
    super.key,
    required this.label,
    required this.transcript,
    required this.backgroundColor,
    required this.borderColor,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 0.6,
              color: Color(0xFF8A8A8A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            transcript,
            style: TextStyle(
              fontSize: isPrimary ? 16.5 : 15.5,
              color: isPrimary ? const Color(0xFFEDEDED) : const Color(0xFFB5B5B5),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

class ImprovedTranscriptCard extends StatelessWidget {
  final TranscriptImprovementResult result;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;

  const ImprovedTranscriptCard({
    super.key,
    required this.result,
    this.onCopy,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI refined',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.6,
                color: Color(0xFF8A8A8A),
              ),
            ),
            const SizedBox(width: 8),
            ConfidenceBadge(confidence: result.confidence),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2D2B5E)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.improvedTranscript,
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFFF1F1F1),
                  height: 1.7,
                ),
              ),
              if (result.changesMade.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.changesMade
                      .take(4)
                      .map(
                        (change) => _ChangeChip(label: change),
                      )
                      .toList(),
                ),
              ],
              if (onCopy != null || onShare != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onCopy != null)
                      Expanded(
                        child: ActionPillButton(
                          icon: Icons.copy,
                          label: 'copy refined',
                          onTap: onCopy!,
                        ),
                      ),
                    if (onCopy != null && onShare != null)
                      const SizedBox(width: 10),
                    if (onShare != null)
                      Expanded(
                        child: ActionPillButton(
                          icon: Icons.share,
                          label: 'share refined',
                          onTap: onShare!,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class RawTranscriptCard extends StatelessWidget {
  final String transcript;

  const RawTranscriptCard({
    super.key,
    required this.transcript,
  });

  @override
  Widget build(BuildContext context) {
    return TranscriptCard(
      label: 'Original transcript',
      transcript: transcript,
      backgroundColor: const Color(0xFF151515),
      borderColor: const Color(0xFF222222),
      isPrimary: false,
    );
  }
}

class EnhanceTranscriptButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const EnhanceTranscriptButton({
    super.key,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF2C2A54)),
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2851), Color(0xFF1A1A1A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B367A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Color(0xFFE8E4FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Improve transcript',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFF1F1F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Clean up speech while preserving intent',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB0B0B0),
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFE8E4FF),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Color(0xFFE8E4FF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TranscriptLoadingCard extends StatelessWidget {
  const TranscriptLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerLine(widthFactor: 0.55),
          SizedBox(height: 12),
          ShimmerLine(widthFactor: 1),
          SizedBox(height: 10),
          ShimmerLine(widthFactor: 0.92),
          SizedBox(height: 10),
          ShimmerLine(widthFactor: 0.75),
        ],
      ),
    );
  }
}

class ActionPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const ActionPillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF534AB7) : const Color(0xFF161616),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isPrimary ? const Color(0xFF534AB7) : const Color(0xFF2A2A2A),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : const Color(0xFF9A9A9A),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isPrimary ? Colors.white : const Color(0xFF9A9A9A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConfidenceBadge extends StatelessWidget {
  final TranscriptConfidence confidence;

  const ConfidenceBadge({
    super.key,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final color = _confidenceColor(confidence);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${confidence.name} confidence',
        style: TextStyle(
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }

  Color _confidenceColor(TranscriptConfidence confidence) {
    switch (confidence) {
      case TranscriptConfidence.high:
        return const Color(0xFF53C1A4);
      case TranscriptConfidence.medium:
        return const Color(0xFFE3C66B);
      case TranscriptConfidence.low:
        return const Color(0xFFE07A7A);
    }
  }
}

class _ChangeChip extends StatelessWidget {
  final String label;

  const _ChangeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF26243A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3A3760)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFFD5D5F5),
        ),
      ),
    );
  }
}

class ShimmerLine extends StatefulWidget {
  final double widthFactor;

  const ShimmerLine({
    super.key,
    required this.widthFactor,
  });

  @override
  State<ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: widget.widthFactor,
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                colors: const [
                  Color(0xFF2A2A2A),
                  Color(0xFF3A3A3A),
                  Color(0xFF2A2A2A),
                ],
                stops: [
                  (_controller.value - 0.3).clamp(0.0, 1.0),
                  _controller.value.clamp(0.0, 1.0),
                  (_controller.value + 0.3).clamp(0.0, 1.0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(rect);
            },
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }
}

