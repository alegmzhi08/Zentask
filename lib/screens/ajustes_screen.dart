// lib/screens/ajustes_screen.dart
import 'package:flutter/material.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  // Estado visual temporal — migrar a Riverpod/Provider cuando se integre
  bool _modoOscuro = false;
  bool _modoEstricto = false;
  bool _recordatorios = true;
  bool _notificacionesRacha = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // ── PERFIL ─────────────────────────────────────────────────────────
          _buildSectionHeader('Perfil'),
          ListTile(
            leading: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF8DC49A),
              child: Icon(Icons.person, color: Colors.white, size: 26),
            ),
            title: const Text(
              'Usuario Zentask',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('usuario@zentask.app'),
            trailing: const Icon(Icons.edit_outlined),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            // TODO: navegar a EditarPerfilScreen
            onTap: () {},
          ),

          // ── APARIENCIA ─────────────────────────────────────────────────────
          _buildSectionHeader('Apariencia'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Modo Oscuro'),
            value: _modoOscuro,
            // TODO: conectar con ThemeProvider o Riverpod para cambiar el tema globalmente
            onChanged: (value) => setState(() => _modoOscuro = value),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Color de Énfasis'),
            subtitle: const Text('Verde Zentask'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF8DC49A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            // TODO: abrir ColorPickerDialog cuando se implemente personalización de temas
            onTap: () {},
          ),

          // ── PRODUCTIVIDAD Y ENFOQUE ────────────────────────────────────────
          _buildSectionHeader('Productividad y Enfoque'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Duración del Pomodoro'),
            subtitle: const Text('25 min trabajo / 5 min descanso'),
            trailing: const Icon(Icons.chevron_right),
            // TODO: abrir PomodoroConfigScreen o un BottomSheet con sliders
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: const Text('Modo Estricto'),
            subtitle: const Text('Bloquea distracciones durante sesiones'),
            value: _modoEstricto,
            // TODO: integrar con un servicio de control de foco (FocusMode API en iOS/Android)
            onChanged: (value) => setState(() => _modoEstricto = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Recordatorios de Tareas'),
            subtitle: const Text('Notificaciones antes de la fecha de entrega'),
            value: _recordatorios,
            // TODO: conectar con flutter_local_notifications
            onChanged: (value) => setState(() => _recordatorios = value),
          ),

          // ── GAMIFICACIÓN ───────────────────────────────────────────────────
          _buildSectionHeader('Gamificación'),
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Notificaciones de Racha'),
            subtitle: const Text('Recibe motivación para mantener tu racha diaria'),
            value: _notificacionesRacha,
            // TODO: conectar con el sistema de rachas en Firestore
            onChanged: (value) => setState(() => _notificacionesRacha = value),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Meta Diaria'),
            subtitle: const Text('Completar 3 tareas'),
            trailing: const Icon(Icons.chevron_right),
            // TODO: abrir MetaDiariaSheet para que el usuario defina su objetivo
            onTap: () {},
          ),

          // ── CUENTA ─────────────────────────────────────────────────────────
          _buildSectionHeader('Cuenta'),
          ListTile(
            leading: Icon(Icons.workspace_premium_outlined, color: colorScheme.primary),
            title: Text(
              'Suscripción Premium',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            subtitle: const Text('Desbloquea todas las funciones de Zentask'),
            trailing: Icon(Icons.chevron_right, color: colorScheme.primary),
            // TODO: navegar a PremiumScreen o abrir RevenueCat paywall
            onTap: () {},
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            // TODO: llamar a FirebaseAuth.instance.signOut() y navegar a LoginScreen
            onTap: () => _confirmarAccionDestructiva(
              context,
              titulo: 'Cerrar sesión',
              mensaje: '¿Seguro que quieres cerrar sesión?',
              etiquetaBoton: 'Cerrar sesión',
              // TODO: FirebaseAuth.instance.signOut()
              onConfirmar: () {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
            subtitle: const Text(
              'Acción irreversible',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            // TODO: llamar a user.delete() en Firebase Auth y borrar datos en Firestore
            onTap: () => _confirmarAccionDestructiva(
              context,
              titulo: 'Eliminar cuenta',
              mensaje:
                  'Esta acción es permanente. Se eliminarán todos tus datos, tareas y gatos virtuales.',
              etiquetaBoton: 'Eliminar para siempre',
              onConfirmar: () {},
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _confirmarAccionDestructiva(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    required String etiquetaBoton,
    required VoidCallback onConfirmar,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirmar();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(etiquetaBoton),
          ),
        ],
      ),
    );
  }
}
