import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/recording/home_screen.dart';
import 'features/transcription/transcription_service.dart';
import '../../shared/services/recording_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const ZenlyApp());
}

class ZenlyApp extends StatelessWidget {
  const ZenlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF534AB7),
          secondary: Color(0xFF7F77DD),
          surface: Color(0xFF1A1A1A),
        ),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
