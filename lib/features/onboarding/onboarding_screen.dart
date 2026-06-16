import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../navigation/main_scaffold.dart';
import '../../main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() async {
    await storageService.setOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScaffold()),
    );
  }

  Future<void> _requestMicPermission() async {
    await Permission.microphone.request();
    _nextPage();
  }

  Future<void> _openKeyboardSettings() async {
    try {
      await const MethodChannel('com.likhinmn.zenly/ime_prefs')
          .invokeMethod('openIMESettings');
    } catch (e) {
      debugPrint('Could not open IME settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  // Step 1: Welcome
                  _buildPage(
                    title: 'Welcome to Zenly',
                    description: 'Your calm, focused space for capturing thoughts with just your voice.',
                    icon: Icons.graphic_eq,
                    primaryActionText: 'Get Started',
                    onPrimaryAction: _nextPage,
                  ),
                  
                  // Step 2: Mic Permission
                  _buildPage(
                    title: 'Microphone Access',
                    description: 'Zenly needs your microphone to transcribe your voice notes locally before sending text to the cloud.',
                    icon: Icons.mic_none,
                    primaryActionText: 'Allow Microphone',
                    onPrimaryAction: _requestMicPermission,
                  ),

                  // Step 3: Keyboard Setup
                  _buildPage(
                    title: 'Type Anywhere',
                    description: 'Enable Zenly\'s custom keyboard to dictate into any app on your device.',
                    icon: Icons.keyboard_alt_outlined,
                    primaryActionText: 'Open Keyboard Settings',
                    onPrimaryAction: _openKeyboardSettings,
                    secondaryActionText: 'Skip for now',
                    onSecondaryAction: _nextPage,
                  ),

                  // Step 4: Done
                  _buildPage(
                    title: 'You\'re All Set',
                    description: 'Tap the mic anytime to start dictating.',
                    icon: Icons.check_circle_outline,
                    primaryActionText: 'Start Recording',
                    onPrimaryAction: _finishOnboarding,
                  ),
                ],
              ),
            ),
            
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final active = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? theme.colorScheme.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData icon,
    required String primaryActionText,
    required VoidCallback onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimaryAction,
              child: Text(primaryActionText),
            ),
          ),
          if (secondaryActionText != null && onSecondaryAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(
                secondaryActionText,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ] else ...[
            const SizedBox(height: 64),
          ],
        ],
      ),
    );
  }
}
