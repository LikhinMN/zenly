import 'package:flutter/material.dart';
import '../../main.dart';
import '../../shared/models/transcript_model.dart';
import '../transcription/transcript_preview_screen.dart';
import 'recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  List<TranscriptModel> _transcripts = [];

  @override
  void initState() {
    super.initState();
    _loadTranscripts();
  }

  void _loadTranscripts() {
    setState(() {
      _transcripts = storageService.getAllTranscripts();
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0)
      return 'Today, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadTranscripts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                'Zenly',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE0E0E0),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'tap to record',
                style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 40),

              // Static waveform
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [10.0, 18.0, 28.0, 20.0, 12.0, 24.0, 16.0, 8.0]
                    .map(
                      (h) => Container(
                        width: 3,
                        height: h,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3C3489),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Record button
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecordingScreen()),
                  );
                  _loadTranscripts();
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF534AB7),
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'tap to record',
                style: TextStyle(fontSize: 11, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 32),

              const Divider(color: Color(0xFF222222)),
              const SizedBox(height: 12),

              // Transcripts list
              Expanded(
                child: _transcripts.isEmpty
                    ? const Center(
                        child: Text(
                          'No transcripts yet.\nRecord something!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _transcripts.length,
                        itemBuilder: (context, index) {
                          final t = _transcripts[index];
                          return Dismissible(
                            key: Key(t.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) async {
                              await storageService.deleteTranscript(t.id);
                              _loadTranscripts();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transcript deleted'),
                                    backgroundColor: Color(0xFF1A1A1A),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            background: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade900,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.centerRight,
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TranscriptPreviewScreen(transcript: t),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.text,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFFCCCCCC),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${_formatTime(t.createdAt)} · ${_formatDuration(t.durationSeconds)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF444444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
