import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/bindings/initial_binding.dart';
import 'presentation/pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  final existing = await storage.read(key: 'api_football_key');
  if (existing == null) {
    await storage.write(key: 'api_football_key', value: const String.fromEnvironment('API_KEY'));
  }
  runApp(const BettingApp());
}

class BettingApp extends StatelessWidget {
  const BettingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BETK',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
        primaryColor: const Color(0xFF3B82F6), // Blue 500
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981), // Emerald 500
        ),
        fontFamily: 'Roboto',
      ),
      initialBinding: InitialBinding(),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
