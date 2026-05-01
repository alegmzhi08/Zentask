import 'package:flutter/material.dart';
import 'screens/main_screen.dart'; // <-- 1. Importamos tu nuevo menú principal

void main() {
  runApp(const ZentaskApp());
}

class ZentaskApp extends StatelessWidget {
  const ZentaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zentask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8DC49A),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(), // <-- 2. Le decimos a la app que arranque desde el menú
    );
  }
}
