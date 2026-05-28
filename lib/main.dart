import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'data/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.seedDefaultUser();
  runApp(const WargaWargiApp());
}

class WargaWargiApp extends StatelessWidget {
  const WargaWargiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WargaWargi App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B365D),
          primary: const Color(0xFF1B365D),
          secondary: const Color(0xFF4A90E2),
          background: const Color(0xFFF5F7FA),
        ),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1B365D), foregroundColor: Colors.white),
      ),
      home: const LoginScreen(),
    );
  }
}