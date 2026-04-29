import 'package:flutter/material.dart';
import 'screens/crear_tarea_screen.dart';

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
      home: CrearTareaScreen(),
    );
  }
}