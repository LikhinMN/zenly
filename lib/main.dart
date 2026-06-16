import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
// ignore: unused_import
import 'overlay_main.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/navigation/main_scaffold.dart';
import 'shared/services/storage_service.dart';
import 'shared/theme/app_theme.dart';

final storageService = StorageService();
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Sync GROQ_TOKEN to the native Android IME
  final token = dotenv.env['GROQ_TOKEN'];
  if (token != null) {
    try {
      await const MethodChannel('com.likhinmn.zenly/ime_prefs')
          .invokeMethod('setGroqToken', {'token': token});
    } catch (e) {
      debugPrint('Failed to sync token to IME: $e');
    }
  }

  await storageService.init();
  runApp(const ProviderScope(child: ZenlyApp()));
}

class ZenlyApp extends StatelessWidget {
  const ZenlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorObservers: [routeObserver],
      home: storageService.hasOnboarded ? const MainScaffold() : const OnboardingScreen(),
    );
  }
}
