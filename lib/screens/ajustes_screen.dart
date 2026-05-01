// lib/screens/ajustes_screen.dart
import 'package:flutter/material.dart';

class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('PREFERENCIAS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: false, // Por ahora estático
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (bool value) {},
            ),
          ),
          const Divider(),
          const SizedBox(height: 20),
          
          const Text('CUENTA', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('Premium Subscription'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
