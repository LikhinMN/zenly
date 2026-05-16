import 'package:flutter/material.dart';
import 'recording_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, String>> _recentTranscripts = const [
    {
      'title': 'Meeting notes — design review',
      'time': 'Today, 2:14 PM · 1m 32s',
    },
    {
      'title': 'Research ideas for sprint 3',
      'time': 'Yesterday · 45s',
    },
  ];

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
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 40),

              // Static waveform
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [10.0, 18.0, 28.0, 20.0, 12.0, 24.0, 16.0, 8.0]
                    .map((h) => Container(
                  width: 3,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3C3489),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Record button
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
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF534AB7),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'tap to record',
                style: TextStyle(fontSize: 11, color: Color(0xFF555555)),
              ),
              const SizedBox(height: 32),

              // Divider
              const Divider(color: Color(0xFF222222)),
              const SizedBox(height: 12),

              // Recent transcripts
              Expanded(
                child: ListView.builder(
                  itemCount: _recentTranscripts.length,
                  itemBuilder: (context, index) {
                    final item = _recentTranscripts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFCCCCCC),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['time']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF444444),
                            ),
                          ),
                        ],
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