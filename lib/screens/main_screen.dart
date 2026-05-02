// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'crear_tarea_screen.dart'; // La pantalla de tus amigos
import 'inicio_screen.dart';      // Tu nueva pantalla
import 'ajustes_screen.dart';     // Tu nueva pantalla

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Empezamos en la pestaña 0 (Inicio)
  int _currentIndex = 0;

  // IndexedStack evita que se recarguen al cambiar de pestaña
  final List<Widget> _screens = [
    const InicioScreen(),
    const CrearTareaScreen(),
    const Placeholder(), // TODO: reemplazar por GaticosScreen cuando esté lista
    const AjustesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // Usamos el color verde de tu tema para el ícono seleccionado
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Nueva Tarea'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Gaticos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
