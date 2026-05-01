// lib/screens/inicio_screen.dart
import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zentask Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sección de Perfil
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF8DC49A), // Tu verde semilla
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Usuario',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Test Zentask #1',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Tarjetas de Estadísticas (Estilo MyStudyLife)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard('Pending Tasks', '0', 'Last 7 days', Colors.amber.shade700),
                _buildStatCard('Overdue Tasks', '5', 'Total', Colors.red.shade400),
                _buildStatCard('Tasks Completed', '0', 'Last 7 days', Colors.green.shade600),
                _buildStatCard('Your Streak', '0', 'Total streak', Colors.orange.shade600),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Widget reutilizable para las tarjetitas
  Widget _buildStatCard(String title, String count, String subtitle, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title, 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(count, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}