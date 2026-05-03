// lib/screens/ajustes_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../services/settings_service.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _modoOscuro = false;
  bool _modoEstricto = false;
  bool _recordatorios = true;
  bool _notificacionesRacha = true;

  @override
  void initState() {
    super.initState();
    SettingsService.instance.init();
  }

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
            title: FutureBuilder<void>(
  future: FirebaseAuth.instance.currentUser?.reload(),
  builder: (context, snapshot) {
    return Text(
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ??
      'Usuario',
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
  },
),
            subtitle: Text(
              FirebaseAuth.instance.currentUser?.email ?? 'Sin correo'),
            trailing: const Icon(Icons.edit_outlined),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {},
          ),

          // ── APARIENCIA ─────────────────────────────────────────────────────
          _buildSectionHeader('Apariencia'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Modo Oscuro'),
            value: _modoOscuro,
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
            onTap: () {},
          ),

          // ── PRODUCTIVIDAD Y ENFOQUE ────────────────────────────────────────
          _buildSectionHeader('Productividad y Enfoque'),
          ListenableBuilder(
            listenable: Listenable.merge([
              SettingsService.instance.pomodoroDuration,
              SettingsService.instance.breakDuration,
            ]),
            builder: (context, _) {
              final work = SettingsService.instance.pomodoroDuration.value;
              final brk = SettingsService.instance.breakDuration.value;
              return ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Duración del Pomodoro'),
                subtitle: Text('$work min trabajo / $brk min descanso'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _abrirConfigPomodoro(context),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.shield_outlined),
            title: const Text('Modo Estricto'),
            subtitle: const Text('Bloquea distracciones durante sesiones'),
            value: _modoEstricto,
            onChanged: (value) => setState(() => _modoEstricto = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Recordatorios de Tareas'),
            subtitle: const Text('Notificaciones antes de la fecha de entrega'),
            value: _recordatorios,
            onChanged: (value) => setState(() => _recordatorios = value),
          ),

          // ── GAMIFICACIÓN ───────────────────────────────────────────────────
          _buildSectionHeader('Gamificación'),
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Notificaciones de Racha'),
            subtitle: const Text('Recibe motivación para mantener tu racha diaria'),
            value: _notificacionesRacha,
            onChanged: (value) => setState(() => _notificacionesRacha = value),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Meta Diaria'),
            subtitle: const Text('Completar 3 tareas'),
            trailing: const Icon(Icons.chevron_right),
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
            onTap: () {},
          ),
          const Divider(indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () => _confirmarAccionDestructiva(
              context,
              titulo: 'Cerrar sesión',
              mensaje: '¿Seguro que quieres cerrar sesión?',
              etiquetaBoton: 'Cerrar sesión',
              onConfirmar: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            title: const Text('Eliminar Cuenta', style: TextStyle(color: Colors.red)),
            subtitle: const Text(
              'Acción irreversible',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            onTap: () => _confirmarAccionDestructiva(
              context,
              titulo: 'Eliminar cuenta',
              mensaje:
                  'Esta acción es permanente. Se eliminarán todos tus datos, tareas y gatos virtuales.',
              etiquetaBoton: 'Eliminar para siempre',
              onConfirmar: () async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    await user?.delete();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por seguridad debes iniciar sesión de nuevo antes de eliminar tu cuenta'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await FirebaseAuth.instance.signOut();
    }
  }
},
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

  void _abrirConfigPomodoro(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PomodoroConfigSheet(),
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

class _PomodoroConfigSheet extends StatefulWidget {
  const _PomodoroConfigSheet();

  @override
  State<_PomodoroConfigSheet> createState() => _PomodoroConfigSheetState();
}

class _PomodoroConfigSheetState extends State<_PomodoroConfigSheet> {
  late int _work;
  late int _brk;

  @override
  void initState() {
    super.initState();
    _work = SettingsService.instance.pomodoroDuration.value;
    _brk = SettingsService.instance.breakDuration.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6E8D8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Configurar Pomodoro',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A4A3E)),
          ),
          const SizedBox(height: 24),
          Text('Trabajo: $_work min',
              style: const TextStyle(fontSize: 14, color: Color(0xFF7D9882))),
          Slider(
            value: _work.toDouble(),
            min: SettingsService.minPomodoroDuration.toDouble(),
            max: SettingsService.maxPomodoroDuration.toDouble(),
            divisions: (SettingsService.maxPomodoroDuration -
                    SettingsService.minPomodoroDuration),
            activeColor: const Color(0xFF8DC49A),
            label: '$_work min',
            onChanged: (v) => setState(() => _work = v.round()),
          ),
          const SizedBox(height: 8),
          Text('Descanso: $_brk min',
              style: const TextStyle(fontSize: 14, color: Color(0xFF7D9882))),
          Slider(
            value: _brk.toDouble(),
            min: SettingsService.minBreakDuration.toDouble(),
            max: SettingsService.maxBreakDuration.toDouble(),
            divisions: (SettingsService.maxBreakDuration -
                    SettingsService.minBreakDuration),
            activeColor: const Color(0xFF8DC49A),
            label: '$_brk min',
            onChanged: (v) => setState(() => _brk = v.round()),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await SettingsService.instance.setPomodoroDuration(_work);
                await SettingsService.instance.setBreakDuration(_brk);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8DC49A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Guardar',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

