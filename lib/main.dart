import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/recording/home_screen.dart';
import 'shared/services/storage_service.dart';

final storageService = StorageService();
final RouteObserver<PageRoute<dynamic>> routeObserver =
    RouteObserver<PageRoute<dynamic>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF534AB7),
          secondary: Color(0xFF7F77DD),
          surface: Color(0xFF1A1A1A),
        ),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      home: const HomeScreen(),
    );
  }
}
