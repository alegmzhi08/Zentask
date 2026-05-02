import 'package:flutter/material.dart';
// Importa aquí tu servicio de economía cuando Claude lo cree
// import 'package:zentask/services/economy_service.dart'; 

class GaticosScreen extends StatelessWidget {
  const GaticosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Gatico Zen'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 100, color: Color(0xFF8DC49A)),
            const SizedBox(height: 20),
            const Text(
              'Área de Recreación',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Aquí aparecerá el compañero virtual que está desarrollando tu equipo.',
                textAlign: TextAlign.center,
              ),
            ),
            // Ejemplo de cómo se vería un botón para gastar puntos
            ElevatedButton.icon(
              onPressed: () {
                // Aquí irá la lógica de: EconomiaZen.gastarCoins(10);
              },
              icon: const Icon(Icons.restaurant),
              label: const Text('Alimentar Gatico (10 🐟)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DC49A),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
